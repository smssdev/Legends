variable "app_version" {
  # أي إصدار يعمل: يضبطه الخط على commit الصورة
  type    = string
  default = "v1"
}

variable "app_copies" {
  type    = number
  default = 2
}

variable "db_password" {
  # لا كلمة مرور في الكود أبداً: تصل متغيراً، من مخزن أسرار الخط
  type      = string
  sensitive = true
}
