output "job_queue_arn" {
  description = "ARN of the Batch job queue, used in nextflow.config"
  value       = aws_batch_job_queue.spot_queue.arn
}

output "s3_bucket_name" {
  description = "S3 bucket for Nextflow workDir"
  value       = aws_s3_bucket.nextflow_workdir.bucket
}