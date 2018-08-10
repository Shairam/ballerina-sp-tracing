import ballerina/io;
import ballerina/mysql;
import ballerina/http;
import ballerina/runtime;
import ballerina/observe;
import ballerina/log;


// type Student is created to store details of a student

documentation {
  `Student` is a user defined object type in Ballerina program. This
    `Student` is used to hold two string data fields .


    F{{id}} This is the description for the `DummyObject`'s field `id`.
                  `F` doc prefix is used to mark a field on Object.
    F{{age}} This is the description for the `DummyObject`'s field `age`.
                  `F` doc prefix is used to mark a field on Object

}
type Student record {
    int id,
    int age,
    string name,
    int mobNo,
    string address,

};

endpoint http:Client self{
    url: " http://localhost:9090"
};

//Endpoint for mysql client
endpoint mysql:Client testDB {
    host: "localhost",
    port: 3306,
    name: "testdb",
    username: "root",
    password: "",
    poolOptions: { maximumPoolSize: 5 },
    dbOptions: { useSSL: false }
};

 // This service listener
  endpoint http:Listener listener {
    port: 9090
};

// Service for the Student data service
@http:ServiceConfig {
    basePath: "/records"
}
service<http:Service> StudentData bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/addStudent"
    }
    // addStudents service used to add student records to the system
    addStudents(endpoint httpConnection, http:Request request) {
            // Initialize an empty http response message
        http:Response response;
        map<string> mp = {"endpoint":"records/addStudent"};
        Student stuData;



        //int spanId2 = check observe:startSpan("Getting request data", tags = mp);
        
        var payloadJson = check request.getJsonPayload();       // Accepting the Json payload sent from a request
        stuData = check <Student>payloadJson;               //Converting the payload to Student type

        //_ = observe:finishSpan(spanId2);

            // Calling the function insertData to update database
       // int spanId3 = check observe:startSpan("Update database span", tags = mp);
          json ret = insertData(stuData.name, stuData.age, stuData.mobNo,
            stuData.address);
         //_ = observe:finishSpan(spanId3);
        // Send the response back to the client with the returned json value from insertData function
        response.setJsonPayload(ret);
       _ = httpConnection->respond(response);


    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/viewAll"
    }
    //viewStudent service to get all the students details and send to the requested user
    viewStudents(endpoint httpConnection, http:Request request){
        map<string> mp = {"Port":"9090"};
        map<string> mp2 = {"endpoint":"/records/viewAll"};
       http:Response response;
       json status = {};
        //log:printError("error occured");
       

            
            // int spanId2 = check observe:startSpan("Database call span");

            var selectRet = testDB->select("SELECT * FROM student", Student,loadToMemory=true); //sending a request to mysql endpoint and getting a response with required data table

            //  _ = observe:finishSpan(spanId2);
           



            table<Student> dt;  // a table is declared with Student as its type
        //match operator used to check if the response returned value with one of the types below
        match selectRet {
        table tableReturned => dt = tableReturned;
        error e => io:println("Select data from student table failed: "
                               + e.message);
        }      
         

       // int spanId3 =  check observe:startSpan("Row iteration span", tags = mp2);
    //student details displayed on server side for reference purpose
    io:println("Iterating data first time:");
    foreach row in dt {
        io:println("Student:" + row.id + "|" + row.name + "|" + row.age);
    }
   
       // _ = observe:finishSpan(spanId3);

      // table is converted to json
    var jsonConversionRet = <json>dt;
    match jsonConversionRet {
        json jsonRes => {
           status = jsonRes;
        }
        error e => {
            status = { "Status": "Data Not available", "Error": e.message };
        }
    }
            //Sending back the converted json data to the request made to this service
            response.setJsonPayload(untaint status);
            _ = httpConnection->respond(response);
    }


    @http:ResourceConfig {
        methods: ["GET"],
        path: "/deleteStu/{stuId}"
    }
    //deleteStudents service for deleteing a student using id
    deleteStudent(endpoint httpConnection, http:Request request,int stuId){
        map<string> mp = {"endpoint":"/records/deleteStu/{stuId}"};

        http:Response response;
            json status = {};


            //calling deleteData function with id as parameter and get a return json object
            var ret = deleteData(stuId);


            io:println(ret);
            //Pass the obtained json object to the request
        response.setJsonPayload(ret);
        _ = httpConnection->respond(response);



    }


     @http:ResourceConfig {
        methods: ["GET"],
        path: "/view/{stuId}"
    }
     //viewOne service to find the details of a particular student using id;
    viewOne(endpoint httpConnection, http:Request request,int stuId){
        http:Response response;
        map<string> mp = {"endpoint":"/view/{studentId}"};

       // int spanId = observe:startRootSpan("Parent");

       // int spanid2 = check observe:startSpan("Get student span", tags = mp, parentSpanId = spanId);
        //findStudent function is called with stuId as parameter and get a return json object
        json result = findStudent(untaint stuId);

        //  _ = observe:finishSpan(spanid2);
        //Pass the obtained json object to the request
            response.setJsonPayload(untaint result);
        _ = httpConnection->respond(response);

       // _ = observe:finishSpan(spanId);

        }


    //@http:ResourceConfig {
    //    methods: ["POST"],
    //    path: "/findDel/{stuId}"
    //}
    ////viewOne service to find the details of a particular student using id;
    //findDelete(endpoint httpConnection, http:Request request,int stuId){
    //    http:Response response;
    //    map<string> mp = {"endpoint":"/findDel/{stuId}"};
    //
    //   // int spanid2 = check  observe:startSpan("find delete span");
    //    var requ= self->get("/records/view/"+ untaint stuId);
    //
    //
    //
    //   // _ = observe:finishSpan(spanid2);
    //    //Pass the obtained json object to the request
    //
    //
    //
    //
    //}


    }

// Function to insert values to database

documentation {
  `insertData` is a function to add data to student records database

    P{{name}} This is the name of the student to be added.

   P{{age}} Student age

   P{{mobNo}} Student mobile number

   P{{address}} Student address.

   R{{}} This function returns a json object. If data is added it returns json containing a status and id of student added.
            If data is not added , it returns the json containing a status and error message.

}
public function insertData(string name, int age, int mobNo, string address) returns (json){
    json updateStatus;
    int uid;
    string sqlString =
    "INSERT INTO student (name, age, mobNo, address) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action
    //  int spanId = check observe:startSpan("update Database");
    var ret = testDB->update(sqlString, name, age, mobNo, address);
   // _  = observe:finishSpan(spanId);

    
    
    // Use match operator to check the validity of the result from database
    match ret {
        int updateRowCount => {


            var result = getId(untaint mobNo); // Getting info of the student added

            match result {
                table dt => {
                    while (dt.hasNext()) {
                        var ret2 = <Student>dt.getNext();
                        match ret2 {
                            Student stu => uid = stu.id;     // Getting the  id of the latest student added
                            error e => io:println("Error in get employee from table: "
                                    + e.message);
                        }
                    }
                }

                error  er => {
                    io:println(er.message);
                }
            }

            updateStatus = { "Status": "Data Inserted Successfully", "id":uid};
        }
        error err => {
            updateStatus = { "Status": "Data Not Inserted", "Error": err.message };
        }
    }
    return updateStatus;
}


documentation {
  `deleteData` is a function to delete a student's data from student records database

    P{{stuId}} This is the id of the student to be deleted.

   R{{}} This function returns a json object. If data is added it returns json containing a status.
            If data is not added , it returns the json containing a status and error message.

}

// Function to delete a student record with id
public function deleteData(int stuId) returns (json) {
    json status = {};
   // int spanId2 = check observe:startSpan("Database update span", tags = mp);
    string sqlString = "DELETE FROM student WHERE id = ?";

    // Delete existing data by invoking update action
    var ret = testDB->update(sqlString,stuId);
   // _ = observe:finishSpan(spanId2);
    io:println(ret);
    match ret {
        int updateRowCount => {
            if (updateRowCount!=1){
                status = { "Status": "Data Not Found" };
            }
            else {
            status = { "Status": "Data Deleted Successfully" };
            }
        }
        error err => {
            status = { "Status": "Data Not Deleted", "Error": err.message };
            io:println(err.message);
        }
    }


    return status;


}

documentation {
  `findStudent` is as function to find a student's data from the student record database

    P{{stuId}} This is the id of the student to be found.

   R{{}} This function returns a json object. If data is added it returns json containing a table of data which is converted to json format.
            If data is not added , it returns the json containing a status and error message.

}

//Function to get a student's details using id
public function findStudent(int stuId) returns (json){
    json status = {};


   // int spanId = check observe:startSpan("Select Data");
    string sqlString = "SELECT * FROM student WHERE id = " + stuId;     // Getting student info of the given ID

    var ret = testDB->select(sqlString, Student,loadToMemory=true);     //Invoking select operation in testDB
   // _ = observe:finishSpan(spanId);

    //Assigning data obtained from db to a table
    table<Student> dt;
    match ret {
        table tableReturned => dt = tableReturned;
        error e => io:println("Select data from student table failed: "
                + e.message);
    }


    //converting the obtained data in table format to json data

    var jsonConversionRet = <json>dt;
    match jsonConversionRet {
        json jsonRes => {
            status = jsonRes;
        }
        error e => {
            status = { "Status": "Data Not available", "Error": e.message };
        }
    }

    return status;
}

public function showMetrics() {
    observe:Metric[] metrics = observe:getAllMetrics();
    foreach metric in metrics {
        io:println();
       io:println(metric.name);
        io:println(metric.tags);
        io:println(metric.value);
        io:println();
    }
}

documentation {
  `getId` is a function to get the Id of the student added in latest.

    P{{mobNo}} This is the mobile number of the student added which is passed as parameter to build up the query.



   R{{}} This function returns either a table which has only one row of the student details or an error.

}
// Function to get the generated Id of the student recently added
public function getId(int mobNo) returns (table|error ) {

  //  int spanId = check observe:startSpan("Select student data");
    //Select data from database by invoking select action
    var ret2 = testDB->select("Select * FROM student WHERE mobNo = "+ mobNo, Student, loadToMemory=true);
  //  _ = observe:finishSpan(spanId);
    table<Student> dt;
    match ret2 {
        table tableReturned => dt = tableReturned;
        error e => io:println("Select data from student table failed: "
                + e.message);
    }

    return dt;

}

// function main(string... args) {

//     io:println("The update operation - Creating a table:");
//     var ret = testDB->update("CREATE TABLE student(id INT AUTO_INCREMENT,
//                           age INT, name VARCHAR(255), PRIMARY KEY (id))");
//     handleUpdate(ret, "Create student table");

//     io:println("\nThe update operation - Inserting data to a table");
//     ret = testDB->update("INSERT INTO student(age, name)
//                           values (23, 'john')");
//     handleUpdate(ret, "Insert to student table with no parameters");

//    io:println("\nThe update operation - Inserting data to a table");
//     ret = testDB->update("INSERT INTO student(age, name)
//                           values (23, 'Peter')");
//     handleUpdate(ret, "Insert to student table with no parameters");

//    io:println("\nThe update operation - Inserting data to a table");
//     ret = testDB->update("INSERT INTO student(age, name)
//                           values (23, 'Jack')");
//     handleUpdate(ret, "Insert to student table with no parameters");

//     io:println("\nThe select operation - Select data from a table");
//     var selectRet = testDB->select("SELECT * FROM student", Student,loadToMemory=true);
//     table<Student> dt;
//     match selectRet {
//         table tableReturned => dt = tableReturned;
//         error e => io:println("Select data from student table failed: "
//                                + e.message);
//     }

//     io:println("Iterating data first time:");
//     foreach row in dt {
//         io:println("Student:" + row.id + "|" + row.name + "|" + row.age);
//     }

//     io:println("\nConvert the table into json");
//     var jsonConversionRet = <json>dt;
//     match jsonConversionRet {
//         json jsonRes => {
//             io:print("JSON: ");
//             io:println(io:sprintf("%s", jsonRes));
//         }
//         error e => io:println("Error in table to json conversion");
//     }

// 	 selectRet = testDB->select("SELECT * FROM student", Student,
//         loadToMemory = true);
    

    


//     //io:println("\nThe update operation - Drop student table");
//     //ret = testDB->update("DROP TABLE student");
//    //handleUpdate(ret, "Drop table student");

//     testDB.stop();
// }

// function handleUpdate(int|error returned, string message) {
//     match returned {
//         int retInt => io:println(message + " status: " + retInt);
//         error e => io:println(message + " failed: " + e.message);
//     }
// }

