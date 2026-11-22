#include "cafe_channels.h"

#include <sys/sysinfo.h>
#include <sys/utsname.h>

#include <cstring>

#include "device_api.g.h"

static int64_t megabytes(unsigned long amount, unsigned int unit) {
  return static_cast<int64_t>(amount) * unit / (1024 * 1024);
}

// The channel by hand: one method, "info", answered with a map.
static FlMethodChannel* device_channel = nullptr;

static void on_device_call(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(call), "info") == 0) {
    struct utsname name;
    uname(&name);
    struct sysinfo memory;
    sysinfo(&memory);
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "system", fl_value_new_string(name.sysname));
    fl_value_set_string_take(result, "version", fl_value_new_string(name.release));
    fl_value_set_string_take(result, "memoryMb", fl_value_new_int(megabytes(memory.totalram, memory.mem_unit)));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(call, response, &error)) {
    g_warning("Failed to answer %s: %s", fl_method_call_get_name(call), error->message);
  }
}

// Pigeon: typed answers, through the generated code.
static CafeDeviceApiInfoResponse* info(gpointer user_data) {
  struct utsname name;
  uname(&name);
  struct sysinfo memory;
  sysinfo(&memory);
  g_autoptr(CafeDeviceInfo) device =
      cafe_device_info_new(name.sysname, name.release, megabytes(memory.totalram, memory.mem_unit));
  return cafe_device_api_info_response_new(device);
}

static CafeDeviceApiBatteryLevelResponse* battery_level(gpointer user_data) {
  g_autofree gchar* text = nullptr;
  if (!g_file_get_contents("/sys/class/power_supply/BAT0/capacity", &text, nullptr, nullptr)) {
    // No battery is an answer too: an error with a code Dart can check.
    return cafe_device_api_battery_level_response_new_error("UNAVAILABLE", "This device has no battery.", nullptr);
  }
  return cafe_device_api_battery_level_response_new(g_ascii_strtoll(text, nullptr, 10));
}

static const CafeDeviceApiVTable device_api = {info, battery_level};

// An event channel: free memory every half second, while Dart listens.
static FlEventChannel* memory_channel = nullptr;
static guint memory_timer = 0;

static gboolean send_free_memory(gpointer user_data) {
  struct sysinfo memory;
  sysinfo(&memory);
  g_autoptr(FlValue) value = fl_value_new_int(megabytes(memory.freeram, memory.mem_unit));
  fl_event_channel_send(memory_channel, value, nullptr, nullptr);
  return G_SOURCE_CONTINUE;
}

static FlMethodErrorResponse* on_listen(FlEventChannel* channel, FlValue* args, gpointer user_data) {
  memory_timer = g_timeout_add(500, send_free_memory, nullptr);
  return nullptr;
}

static FlMethodErrorResponse* on_cancel(FlEventChannel* channel, FlValue* args, gpointer user_data) {
  g_clear_handle_id(&memory_timer, g_source_remove);
  return nullptr;
}

void cafe_channels_register(FlBinaryMessenger* messenger) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  device_channel = fl_method_channel_new(messenger, "bitcafe/device", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(device_channel, on_device_call, nullptr, nullptr);

  cafe_device_api_set_method_handlers(messenger, nullptr, &device_api, nullptr, nullptr);

  memory_channel = fl_event_channel_new(messenger, "bitcafe/memory", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(memory_channel, on_listen, on_cancel, nullptr, nullptr);
}
