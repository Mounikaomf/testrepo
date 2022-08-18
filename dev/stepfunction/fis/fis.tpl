{
  "StartAt": "Glue StartJobRun",
  "TimeoutSeconds": 36000,
  "States": {
	"Glue StartJobRun": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
	  "ResultPath": null,
      "Parameters": {
        "JobName": "${job_name}",
        "Arguments": {
          "--bucket": "${bucket}",
		  "--target_prefix.$" : "$.prepared_prefix",
          "--bucket_config": "${bucket_config}",
          "--source_prefix.$": "$.raw_prefix",
          "--copybook_prefix": "${copybook_prefix}",
          "--header_copybook_prefix": "${header_copybook_prefix}"
        }
      },
       "Next": "Lambda prep2exchange"
    },
    "Lambda prep2exchange": {
      "Type":"Task",
      "Resource":"arn:aws:states:::lambda:invoke",
	  "ResultPath": null,
      "Parameters":{
            "FunctionName":"${prep2exchange_function_name}",
            "Payload":{
               "bucket":"${target_bucket}",
               "prefix.$":"$.prepared_prefix"
            }
         },
      "Next": "Load data to Snowflake"
    },
    "Load data to Snowflake": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "ResultPath" : null,
      "Parameters": {
        "Payload": {
          "SQL_QUERY_FILE": "${sql_query_file}",
          "SOURCE_DIRECTORY.$": "$.exchange_prefix"
        },
        "FunctionName": "${sf_function_name}"
      },
      "End" : true
    }
  }
}
