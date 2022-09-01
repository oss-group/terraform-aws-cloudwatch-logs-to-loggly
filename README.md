# AWS Log shipping to Loggly Lambda function, based on blueprint

Terraform module which creates a lambda function for shipping logs to Loggly.

See Loggly documentation
https://documentation.solarwinds.com/en/success_center/loggly/content/admin/cloudwatch-logs.htm

## Usage


```hcl
module "cloudwatch-logs-to-loggly" {
  source  = "OSSG/cloudwatch-logs-to-loggly"
  version = "0.1.0"
  logglyTags = "appname,dev,cloudwatch"
  kmsEncryptedCustomerToken = "xxx"
  kmskeyId = "aws/lambda" 
  lambda_function_suffix = "appname-dev"
  cloudwatch_groups_to_ship = toset(["/aws/logs/appname-a", "/aws/logs/appname-b"])
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
```
## Authors

Module is maintained by [Glen Ogilvie](https://github.com/nelg) 

## License

Apache 2 Licensed. See [LICENSE]
The lambda_code supplied in this module is part of the blueprint available via the AWS console.
