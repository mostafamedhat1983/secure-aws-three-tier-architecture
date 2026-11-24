
# CloudTrail records AWS account activity and delivers logs to S3.
resource "aws_cloudtrail" "main" {
  name           = "securevault-cloudtrail"
  s3_bucket_name = "depi-cloudtrail"

  # Collect events from all enabled AWS regions.
  is_multi_region_trail = true

  # Include global service events, such as IAM activity.
  include_global_service_events = true

  # Enable integrity validation for delivered log files.
  enable_log_file_validation = true

  # Record management events (both read and write).
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name = "securevault-cloudtrail"
  }
}
