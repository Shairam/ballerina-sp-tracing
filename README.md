  
# -Service 
This is basically a small student record system. This service is mainly created focusing on the integration with Honeycomb for observability purpose. 

The student data are stored in the local mysql database.
The sql file has been included in the repo for your ease.
Run this sql file to create the database locally.

The config file is also included in the repo for the configurations to be made to send traces to zipkin.

There are two files namely records.bal and main.bal.


records.bal is the service provider.

main.bal is the client to make calls for the resources in records.bal.


# Prerequisites
Docker

MYSQL

Ballerina

Maven 

# Configuring your service
In order to send trace data to Zipkin, configurations are to be done as follows.

1. Create a file with name ballerina.conf
2. Add the following lines :-

        [b7a.observability.tracing]
        enabled=true
        name="zipkin"
        
        # reporter.hostname will be your host machine
        # reporter.port will be the port your service will report the traces to
        [b7a.observability.tracing.zipkin]
        reporter.hostname="localhost"
        reporter.port=9411

        #Send the spans in V1 format as honeycomb-opentracing-proxy supports on V1
        reporter.api.context="/api/v1/spans"
        reporter.api.version="v1"

        reporter.compression.enabled=false

3.  While running the service you are to use this file to configure your service.(shown later below).

    
# Adding Zipkin Dependencies

1. Go to ballerina-observability and clone the GitHub repository in any preferred location.
2. Make sure you have installed Apache Maven.
 
3. Build the repository by running the following command from the terminal in the root project directory ballerina-observability.

               mvn clean install                                
4.   Go to the path - 
        ballerina-observability/tracing-extensions/modules/ballerina-zipkin-extension/target/ and extract distribution.zip.
5.  Copy all the JAR files inside the distribution.zip to 'bre/lib' directory in ballerina distribution that you have installed.

# How to start and observe

1. You need to start the honeycomb-opentracing-proxy. This can be done by using docker. Docker is used to pull the image for honeycomb-opentracing-proxy.

  Run the following command :- 

     docker run -p 9411:9411 honeycombio/honeycomb-opentracing-proxy -k APIKEY -d traces

  -k represent the APi Key you will be getting when you sign in to honeycomb account.

  -d represents the dataset you are going to send your trace data to.


2.   Start the records.bal service using :-

         ballerina run --config <path-to-ballerina-conf>/ballerina.conf <path-to-records.bal>/records.bal

3.  Start the main.bal using the below commands and perform some operations in order to observe your traces in honeycomb.
            
        ballerina run  <path-to-main.bal>/main.bal
    


