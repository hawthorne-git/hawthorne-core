module HawthorneCore::AwsHelper

  # ----------------------------------------------------------------

  def trim_aws_image_url(url)
    url[0, url.index('?')]
  end

  def full_aws_image_url(key)
    ENV['AWS_ROOT_URL'] + '/' + key
  end

  # ----------------------------------------------------------------

  def aws_core_bucket_url
    'https://core-bucket-core.s3.us-east-1.amazonaws.com'
  end

  def aws_hawthorne_bucket_url
    'https://hawthorne-s3-bucket.s3.us-east-2.amazonaws.com'
  end

  # ----------------------------------------------------------------

  def aws_hawthorne_core_directory_url
    aws_core_bucket_url + '/hawthorne-core'
  end

  # ----------------------------------------------------------------

  def month_overlay_url(month)
    aws_hawthorne_core_directory_url + '/month-overlay/' + month.downcase + '.png'
  end

  # ----------------------------------------------------------------

end