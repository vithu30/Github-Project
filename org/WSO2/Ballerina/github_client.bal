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

package org.WSO2.Ballerina;

import ballerina.net.http;
import ballerina.collections;
import ballerina.config;
import ballerina.log;
import ballerina.runtime;
import ballerina.io;

boolean hasNextPage = true;
string endCursor;
string organization = "wso2";
http:HttpClient httpGithubClient = create http:HttpClient ("https://api.github.com/graphql",{});

@Description { value:"get all repositories name by traversing all pages"}
public function getRepositories () (collections:Vector) {
    log:printInfo("Connection established with github API");
    string repositoryQuery;
    collections:Vector responseVector = {vec:[]};
    boolean flag = true;
    while(hasNextPage){
        if(flag){
            repositoryQuery  = string `{"{{GIT_VARIABLES}}":{"{{GIT_LOGIN}}":"{{organization}}"},
                                            "{{GIT_QUERY}}":"{{FIRST_PAGE_REPOSITORY_QUERY}}"}`;
            flag = false;
        }
        else{
            repositoryQuery = string `{"{{GIT_VARIABLES}}":
                                        {"{{GIT_LOGIN}}":"{{organization}}","{{GIT_END_CURSOR}}":"{{endCursor}}"},
                                        "{{GIT_QUERY}}":"{{NEXT_PAGE_REPOSITORY_QUERY}}"}`;
        }
        
        var jsonQuery, _ = <json> repositoryQuery;
        json response = generateHttpClient(jsonQuery);
        responseVector.add(response);
        error typeConversionError;
        try{
            hasNextPage, typeConversionError =
            <boolean> response.data.organization.repositories.pageInfo.hasNextPage.toString();
        } catch (error err) {
            log:printError("Error in fetching data from GraphQL API : " + err.message);
            if(typeConversionError != null){
                log:printError("Error occured in conversion to boolean : " + typeConversionError.message);
            }
        }
        if(hasNextPage){
            endCursor =  response.data.organization.repositories.pageInfo.endCursor.toString();
        }
    }
    log:printInfo("List of repositories is generated");
    return responseVector;
}

@Description { value:"get pull requests of given repositories (with pagination)"}
@Param { value:"responseVector: vector contains all repositories name"}
public function getPullRequests (collections:Vector responseVector) {
    log:printInfo("Connection established with github API");
    int numberOfPages = responseVector.vectorSize;
    int pageIterator;
    int numberOfRepositories;
    string endCursor;
    string repositoryName;
    boolean flag = true;
    hasNextPage = true;
    while(pageIterator < numberOfPages) {
        var response, typeConversionError = (json)responseVector.get(pageIterator);
        if(typeConversionError != null){
            log:printError("Error in conversion to json : " + typeConversionError.message);
        }
        numberOfRepositories = lengthof response.data.organization.repositories.nodes;
        int repositoryIterator;
        while(repositoryIterator < numberOfRepositories) {
            repositoryName = response.data.organization.repositories.nodes[repositoryIterator].name.toString();
            log:printInfo("Get pull requests of repository - " + repositoryName);
            hasNextPage = true;
            flag = true;
            string pullRequestQuery;
            while(hasNextPage){
                if(flag){
                    pullRequestQuery = string `{"{{GIT_VARIABLES}}":
                    {"{{GIT_LOGIN}}":"{{organization}}","{{GIT_NAME}}":"{{repositoryName}}"},
                    "{{GIT_QUERY}}":"{{FIRST_PAGE_PULL_REQUEST_QUERY}}"}`;
                    flag = false;
                }
                else{
                    pullRequestQuery = string `{"{{GIT_VARIABLES}}":
                    {"{{GIT_LOGIN}}":"{{organization}}","{{GIT_NAME}}":"{{repositoryName}}",
                            "{{GIT_END_CURSOR}}":"{{endCursor}}"},"{{GIT_QUERY}}":"{{NEXT_PAGE_PULL_REQUEST_QUERY}}"}`;
                }
                var jsonPayload, _ = <json> pullRequestQuery;
                json pullRequests = generateHttpClient(jsonPayload).data.organization.repository.pullRequests;
                error typeCastError;
                hasNextPage, typeCastError = <boolean> pullRequests.pageInfo.hasNextPage.toString();
                if(hasNextPage){
                    endCursor =  pullRequests.pageInfo.endCursor.toString();
                }
                if(pullRequests.nodes != null){
                    generateData(pullRequests, "pullRequest");
                }
            }
            repositoryIterator = repositoryIterator + 1;
        }
        pageIterator = pageIterator + 1;
    }
}

@Description { value:"get issues of given repositories (with pagination)"}
@Param { value:"responseVector: vector contains all repositories name"}
public function getIssues (collections:Vector responseVector) {
    int numberOfPages = responseVector.vectorSize;
    int pageIterator;
    int numberOfRepositories;
    string endCursor = "";
    string repositoryName;
    string issueQuery;
    hasNextPage = true;
    boolean flag = true;
    while(pageIterator < numberOfPages) {
        var response, typeConversionError = (json)responseVector.get(pageIterator);
        if(typeConversionError != null){
            log:printError("Error in conversion to json : " + typeConversionError.message);
        }
        numberOfRepositories = lengthof response.data.organization.repositories.nodes;
        int repositoryIterator;
        while(repositoryIterator < numberOfRepositories) {
            repositoryName = response.data.organization.repositories.nodes[repositoryIterator].name.toString();
            log:printInfo("Get issues of repository - " + repositoryName);
            hasNextPage = true;
            flag = true;
            endCursor = "";
            while(hasNextPage){
                if(flag){
                    issueQuery = string `{"{{GIT_VARIABLES}}":{"{{GIT_LOGIN}}":"{{organization}}",
                    "{{GIT_NAME}}":"{{repositoryName}}"},"{{GIT_QUERY}}":"{{FIRST_PAGE_ISSUE_QUERY}}"}`;
                    flag = false;
                }
                else{
                    issueQuery = string `{"{{GIT_VARIABLES}}":{"{{GIT_LOGIN}}":"{{organization}}",
                    "{{GIT_NAME}}":"{{repositoryName}}","{{GIT_END_CURSOR}}":"{{endCursor}}"},
                    "{{GIT_QUERY}}":"{{NEXT_PAGE_ISSUE_QUERY}}"}`;
                }
                var jsonPayload, _ = <json> issueQuery;
                error typeCastError;
                json issues = generateHttpClient(jsonPayload).data.organization.repository.issues;
                hasNextPage, typeCastError = <boolean> issues.pageInfo.hasNextPage.toString();
                if(hasNextPage){
                    endCursor = issues.pageInfo.endCursor.toString();
                }
                if(issues.nodes != null){
                    generateData(issues, "issue");
                }
            }
            repositoryIterator = repositoryIterator + 1;
        }
        pageIterator = pageIterator + 1;
    }
}

public function generateHttpClient (json jsonPayload) (json) {
    endpoint <http:HttpClient> httpGithubEP {
        httpGithubClient;
    }
    http:OutRequest httpOutRequest = {};
    http:InResponse httpInResponse = {};
    httpOutRequest.addHeader("Authorization","Bearer " + config:getGlobalValue("ACCESS_TOKEN"));
    httpOutRequest.setJsonPayload(jsonPayload);
    http:HttpConnectorError  httpConnectError;
    httpInResponse,httpConnectError = httpGithubEP.post("",httpOutRequest);
    if(httpConnectorError != null) {
        log:printInfo("Error in post request : " + httpConnectorError.message);
    }
    json response = httpInResponse.getJsonPayload();
    return response;
}