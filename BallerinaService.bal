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

sql:ClientConnector clientConnector = create sql:ClientConnector(
                                        sql:DB.MYSQL,
                                        "localhost",
                                         3306,
                                        "FilteredData",
                                        "root",
                                        "Password.123",
                                        {maximumPoolSize:5,
                                            url:"jdbc:mysql://localhost:3306/FilteredData?useSSL=false"});


service<http> ballerinaService {
    @http:resourceConfig {
        methods:["GET"]
    }
    
    resource pullRequests(http:Connection httpConnection, http:InRequest inRequest) {
        http:OutResponse outResponse = {};

        json jsonPayload = databaseConnector("SELECT RepositoryName,Url,Days,Weeks,githubId,product,State FROM pullRequests
        LEFT OUTER JOIN WSO2contributors ON pullRequests.GithubId=WSO2contributors.userId LEFT OUTER JOIN product ON
                pullRequests.RepositoryName=product.RepoName WHERE WSO2contributors.userId is null");

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
        json jsonPayload = databaseConnector("SELECT productName, SUM(totalNum) as Total FROM (SELECT IFNULL(product.Product,\"unknown\") as productName, COUNT(*) as totalNum FROM pullRequests LEFT OUTER JOIN
WSO2contributors ON pullRequests.GithubId=WSO2contributors.userId LEFT OUTER JOIN product ON
pullRequests.RepositoryName=product.RepoName WHERE WSO2contributors.userId is null GROUP BY product.Product) AS T GROUP BY productName ");
        
        outResponse.addHeader("Access-Control-Allow-Origin","*");
        outResponse.setJsonPayload(jsonPayload);

        _ = httpConnection.respond(outResponse);
    }
    
    resource issues(http:Connection httpConnection, http:InRequest inRequest){
        http:OutResponse outResponse = {};
    
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
        json jsonPayload = databaseConnector("SELECT productName, SUM(totalNum) as Total FROM (SELECT IFNULL(product.Product,\"unknown\") as productName, COUNT(*) as totalNum FROM issues LEFT OUTER JOIN
WSO2contributors ON issues.GithubId=WSO2contributors.userId LEFT OUTER JOIN product ON
issues.RepositoryName=product.RepoName WHERE WSO2contributors.userId is null GROUP BY product.Product) AS T GROUP BY productName");
        
        outResponse.addHeader("Access-Control-Allow-Origin","*");
        outResponse.setJsonPayload(jsonPayload);
    
        _ = httpConnection.respond(outResponse);
    }
}

function databaseConnector(string stringPayload)(json jsonPayload){
    endpoint<sql:ClientConnector> testDB {
        clientConnector;
        }

    table data = testDB.select(stringPayload,null,null);
    jsonPayload,_ = <json>data;
    jsonPayload = jsonPayload;
    return;
}
