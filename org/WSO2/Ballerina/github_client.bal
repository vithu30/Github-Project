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

boolean hasNextPage = true;
string repositoryName;
int numberOfRepositories;
//json response;
json issues;
json pullRequests;
http:OutRequest httpOutRequest;
http:InResponse httpInResponse;
http:HttpClient httpGithubClient = create http:HttpClient ("https://api.github.com/graphql",{});

public function getRepositories () (collections:Vector) {
    endpoint <http:HttpClient> httpGithubEP {
        httpGithubClient;
    }
    string QUERY;
    string endCursor = "";
    collections:Vector responseVector = {vec:[]};
    while(hasNextPage){
        httpOutRequest = {};
        httpInResponse = {};
        QUERY = string `{
                            organization(login:\"wso2\") {
                                repositories(first: 100,after:{{endCursor}}) {
                                    pageInfo {
                                        hasNextPage
                                        endCursor
                                    }
                                    nodes {
                                        name
                                    }
                                }
                            }
                        }`;


        httpOutRequest.addHeader("Authorization" , "Bearer " + config:getGlobalValue("access_token"));
        json jsonPayLoad = {query:QUERY};
        httpOutRequest.setJsonPayload(jsonPayLoad);
        http:HttpConnectorError httpConnectorError;
        httpInResponse, httpConnectorError = httpGithubEP.post("", httpOutRequest);
        if(httpConnectorError != null) {
            log:printInfo("Error in post request : " + httpConnectorError.message);
        }
        json response = httpInResponse.getJsonPayload();
        
        responseVector.add(response);
        error typeConversionError;
        hasNextPage, typeConversionError = <boolean> response.data.organization.repositories.pageInfo.hasNextPage.toString();
        if(typeConversionError != null){
            log:printInfo("Error occured in conversion to boolean : " + typeConversionError.message);
        }
        if(hasNextPage){
            endCursor = "\"" + response.data.organization.repositories.pageInfo.endCursor.toString() + "\"";
        }
    }
    return responseVector;
}

public function getPullRequests (collections:Vector responseVector) {
    endpoint <http:HttpClient> httpGithubEP {
        httpGithubClient;
    }

    int numberOfPages = responseVector.vectorSize;
    int pageIterator;
    string endCursor = "";
    hasNextPage = true;

    while(pageIterator < numberOfPages) {
        var response, typeConversionError = (json)responseVector.get(pageIterator);
        if(typeConversionError != null){
            log:printInfo("Error in conversion to json : " + typeConversionError.message);
        }
        numberOfRepositories = lengthof response.data.organization.repositories.nodes;
        int repositoryIterator;
        while(repositoryIterator < numberOfRepositories) {
            repositoryName = response.data.organization.repositories.nodes[repositoryIterator].name.toString();
            hasNextPage = true;
            endCursor = "";
            
            while(hasNextPage){
                httpOutRequest = {};
                httpInResponse = {};
                httpOutRequest.addHeader("Authorization","Bearer " + config:getGlobalValue("access_token"));
                string QUERY = string `{
                                            organization(login:\"wso2\") {
                                                repository(name:\"{{repositoryName}}\") {
                                                    pullRequests(first:100, states:[OPEN],after:{{endCursor}}) {
                                                        pageInfo{
                                                            hasNextPage
                                                            endCursor
                                                        }
                                                        nodes {
                                                            repository {
                                                                name
                                                            }
                                                            createdAt
                                                            url
                                                            author {
                                                                login
                                                            }
                                                            reviews(last:1, states:[APPROVED,CHANGES_REQUESTED,
                                                                DISMISSED,PENDING,COMMENTED]){
                        	                                    nodes{
                                                                    state
                                                                }
                                                            }
                                                        }

                                                    }

                                                }
                                            }
                                        }`;

                json payload = {query:QUERY};
                httpOutRequest.setJsonPayload(payload);
                http:HttpConnectorError  httpConnectError;
                httpInResponse,httpConnectError = httpGithubEP.post("",httpOutRequest);
                if(httpConnectError != null){
                    log:printInfo("Error in post request : " + httpConnectError.message);
                }
                pullRequests = httpInResponse.getJsonPayload().data.organization.repository.pullRequests;
                error typeConversionError;
                hasNextPage, typeConversionError = <boolean > pullRequests.pageInfo.hasNextPage.toString();
                if(hasNextPage){
                    endCursor = "\"" + pullRequests.pageInfo.endCursor.toString() + "\"";
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

public function getIssues (collections:Vector responseVector) {
    endpoint <http:HttpClient> httpGithubClient {
        create http:HttpClient ("https://api.github.com/graphql",{});
    }

    int numberOfPages = responseVector.vectorSize;
    int pageIterator;
    string endCursor = "";
    hasNextPage = true;

    while(pageIterator < numberOfPages) {
        var response, typeCastError = (json)responseVector.get(pageIterator);
        if(typeCastError != null){
            log:printInfo("Error in conversion to json : " + typeCastError.message);
        }
        numberOfRepositories = lengthof response.data.organization.repositories.nodes;
        int repositoryIterator;
        while(repositoryIterator < numberOfRepositories) {
            repositoryName = response.data.organization.repositories.nodes[repositoryIterator].name.toString();
            hasNextPage = true;
            endCursor = "";

            while(hasNextPage){
                httpOutRequest = {};
                httpInResponse = {};

                httpOutRequest.addHeader("Authorization","Bearer "+config:getGlobalValue("access_token"));
                string QUERY = string `{
                                            organization(login:\"wso2\") {
                                                repository(name:\"{{repositoryName}}\") {
                                                    issues(first:100, states:[OPEN],after:{{endCursor}}) {
                                                        pageInfo {
                                                            hasNextPage
                                                            endCursor
                                                        }

                                                        nodes {
                                                            repository {
                                                                name
                                                            }
                                                            createdAt
                                                            url
                                                            author {
                                                              login
                                                            }
                                                        }

                                                    }
                                                }
                                            }
                                        }`;

                json payload = {query:QUERY};
                httpOutRequest.setJsonPayload(payload);
                http:HttpConnectorError  httpConnectError;
                httpInResponse,httpConnectError = httpGithubClient.post("",httpOutRequest);
                if(httpConnectError != null){
                    log:printInfo("Error in post request : " + httpConnectError.message);
                }
                issues = httpInResponse.getJsonPayload().data.organization.repository.issues;
                error typeConversionError;
                hasNextPage, typeConversionError = <boolean > issues.pageInfo.hasNextPage.toString();
                if(hasNextPage){
                    endCursor = "\"" + issues.pageInfo.endCursor.toString() + "\"";
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
