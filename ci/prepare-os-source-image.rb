#!/usr/bin/env ruby

require('fileutils')
require('open3')

OS_SOURCE_IMAGE_SEPARATOR = ','
RESOURCE_NOT_FOUND_ERROR = 'Could not find resource'

os_source_images = ENV['OS_SOURCE_IMAGE']
os_source_image_artifact = ENV['GITLAB_OS_SOURCE_IMAGE_ARTIFACT']

# Ensure artifact directory exists
os_source_image_artifact_dir = File.dirname(os_source_image_artifact)
FileUtils.mkdir_p(os_source_image_artifact_dir)

written = false
os_source_images.split(OS_SOURCE_IMAGE_SEPARATOR).each do |image|
    std_out, std_err, status = Open3.capture3("openstack image show -c id -f value '#{image}'")
    if status.exitstatus != 0
        unless std_err.include?(RESOURCE_NOT_FOUND_ERROR)
            raise("Error connecting to OpenStack: #{std_err}")
        end
    else
        image_id = std_out.strip!
        File.write(os_source_image_artifact, image_id)
        puts("Written source image ID \"#{image_id}\" to \"#{os_source_image_artifact}\"")
        break
    end
end

unless written
    raise "No matching images found in OpenStack: #{os_source_images}"
end
