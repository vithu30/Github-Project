// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina.net.http;
import ballerina.data.sql;
import ballerina.log;
import ballerina.config;
import org.WSO2.Ballerina;

string username = config:getGlobalValue("USERNAME");
string password = config:getGlobalValue("PASSWORD");
string hostOrPath = config:getGlobalValue("HOST");
string databaseName = config:getGlobalValue("DATABASE_NAME");
int port = Ballerina:getPortNumber();
sql:ClientConnector clientConnector = create sql:ClientConnector(
                                        sql:DB.MYSQL,
                                        hostOrPath,
                                        port,
                                        databaseName+"?useSSL=false",
                                        username,
                                        password,
                                        {maximumPoolSize:5});


service<http> ballerinaService {
    @http:resourceConfig {methods:["GET"]}
    resource pullRequests(http:Connection httpConnection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};

        // Query to return pull requests sent by outsiders ,  repositories ,
        // respective product , url of pull request and open duration by
        // comparing list whole open pull requests with list of users from WSO2
        // and product, repositories mapping.

        json jsonPayload = databaseConnector("SELECT RepositoryName,Url,Days,Weeks,githubId,product,State FROM
        pullRequests LEFT OUTER JOIN WSO2contributors ON pullRequests.GithubId=WSO2contributors.userId LEFT OUTER JOIN
        product ON pullRequests.RepositoryName=product.RepoName WHERE WSO2contributors.userId is null");
        int iterator;
        while(iterator < lengthof jsonPayload){
            if(jsonPayload[iterator].product == null){
                jsonPayload[iterator].product = "unknown";
            }
            iterator = iterator + 1;
        }
        outResponse.addHeader("Access-Control-Allow-Origin","*");
        outResponse.setJsonPayload(jsonPayload);
        _ = httpConnection.respond(outResponse);
    }

    resource summaryOfPullRequests(http:Connection httpConnection,http:InRequest inRequest){
        http:OutResponse outResponse = {};

        // Query to return the total number of pull requests sent by outsiders
        // for each product where repositories which do not have jenkins build
        // also accumulated under 'unknown'.
        
        json jsonPayload = databaseConnector("SELECT productName, SUM(totalNum) as Total FROM
        (SELECT IFNULL(product.Product,\"unknown\") as productName, COUNT(*) as totalNum FROM
        pullRequests LEFT OUTER JOIN WSO2contributors ON pullRequests.GithubId=WSO2contributors.userId
        LEFT OUTER JOIN product ON pullRequests.RepositoryName=product.RepoName WHERE WSO2contributors.userId
        is null GROUP BY product.Product) AS T GROUP BY productName ");
        outResponse.addHeader("Access-Control-Allow-Origin","*");
        outResponse.setJsonPayload(jsonPayload);
        _ = httpConnection.respond(outResponse);
    }
    
    resource issues(http:Connection httpConnection, http:InRequest inRequest){
        http:OutResponse outResponse = {};

        // Query to return issues sent by outsiders ,  repositories ,
        // respective product , url of issue and open duration by
        // comparing list of whole open issues with list of users from WSO2
        // and product, repositories mapping.
    
        json jsonPayload = databaseConnector("SELECT RepositoryName,Url,Days,Weeks,githubId,product FROM issues
        LEFT OUTER JOIN WSO2contributors ON issues.GithubId=WSO2contributors.userId LEFT OUTER JOIN product ON
        issues.RepositoryName=product.RepoName WHERE WSO2contributors.userId is null");
        int iterator;
        while(iterator < lengthof jsonPayload){
            if(jsonPayload[iterator].product == null){
                jsonPayload[iterator].product = "unknown";
            }
            iterator = iterator + 1;
        }
        outResponse.addHeader("Access-Control-Allow-Origin","*");
        outResponse.setJsonPayload(jsonPayload);
        _ = httpConnection.respond(outResponse);
    }

    resource summaryOfIssues(http:Connection httpConnection, http:InRequest inRequest){
        http:OutResponse outResponse = {};

        // Query to return the total number of issues sent by outsiders
        // for each product where repositories which do not have jenkins build
        // also accumulated under 'unknown'.
        
        json jsonPayload = databaseConnector("SELECT productName, SUM(totalNum) as Total FROM (SELECT IFNULL
        (product.Product,\"unknown\") as productName, COUNT(*) as totalNum FROM issues LEFT OUTER JOIN
        WSO2contributors ON issues.GithubId=WSO2contributors.userId LEFT OUTER JOIN product ON
        issues.RepositoryName=product.RepoName WHERE WSO2contributors.userId is null GROUP BY
        product.Product) AS T GROUP BY productName");
        outResponse.addHeader("Access-Control-Allow-Origin","*");
        outResponse.setJsonPayload(jsonPayload);
        _ = httpConnection.respond(outResponse);
    }
}

@Description { value:"establish connection with database and fetch data"}
@Param { value:"stringPayload: mySQL query as string"}
function databaseConnector(string stringPayload)(json jsonPayload){
    endpoint<sql:ClientConnector> testDB {
        clientConnector;
    }
    table data = testDB.select(stringPayload,null,null);
    error typeCastError;
    jsonPayload, typeCastError = <json>data;
    if(typeCastError != null){
        log:printInfo("Error in casting : " + typeCastError.message);
    }
    return;
}
