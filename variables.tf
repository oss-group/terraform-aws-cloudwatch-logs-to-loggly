variable "logglyTags" {
  description = "String of comma seperated tags used for loggly"
}
variable "logglyHostName" {
  description = "Loggly host"
  default = "logs-01.loggly.com"
}
variable "kmsEncryptedCustomerToken" {
  description = "See: https://documentation.solarwinds.com/en/success_center/loggly/content/admin/cloudwatch-logs.htm"
}
variable "lambda_function_suffix" {
  default = ""
  description = "Lambda function suffix to use"
}
variable "tags" {
  type = map
  default = {}
}
variable "cloudwatch_groups_to_ship" {
  type = list
  default = []
  description = "names of cloudwatch log groups to ship to Loggly"
}
variable "filter" {
  default = ""
  description = "common filter for log groups. Leave blank for all."
}
variable "kms_key_alias" {
  default = "alias/aws/lambda"
  description = "KMS key alias used for decrypting the kmsEncryptedCustomerToken"
}