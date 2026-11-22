#ifndef RUNNER_CAFE_CHANNELS_H_
#define RUNNER_CAFE_CHANNELS_H_

#include <flutter_linux/flutter_linux.h>

// تُنادى مرة واحدة، حين توجد النافذة وعرض Flutter فيها.
void cafe_channels_register(FlBinaryMessenger* messenger);

#endif  // RUNNER_CAFE_CHANNELS_H_
