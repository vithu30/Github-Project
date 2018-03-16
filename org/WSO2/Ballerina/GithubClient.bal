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

string endCursor="";
string hasNextPage = "true";
string repositoryName;
int pageIterator;
int numberOfRepositories;
int repositoryIterator;
json response;
json issues;
json pullRequests;
http:HttpClient httpGithubClient = create http:HttpClient ("https://api.github.com/graphql",{});

public function getRepositories () (collections:Vector) {
    endpoint <http:HttpClient> httpGithubEP {
        httpGithubClient;
    }

    string QUERY;
    collections:Vector responseVector = {vec:[]};
    http:OutRequest httpRequest;
    http:InResponse httpResponse;

    while(hasNextPage=="true"){
        httpRequest = {};
        httpResponse = {};
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


        httpRequest.addHeader("Authorization" , "Bearer " + config:getGlobalValue("access_token"));
        json jsonPayLoad = {query:QUERY};
        httpRequest.setJsonPayload(jsonPayLoad);
        http:HttpConnectorError httpConnectorError;
        httpResponse, httpConnectorError = httpGithubEP.post("", httpRequest);
        if(httpConnectorError != null) {
            log:printInfo("Error in post request : " + httpConnectorError.message);
        }
        json response = httpResponse.getJsonPayload();
        
        responseVector.add(response);
        hasNextPage = response.data.organization.repositories.pageInfo.hasNextPage.toString();
        if(hasNextPage == "true"){
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
    pageIterator = 0;
    endCursor = "";
    hasNextPage = "true";

    while(pageIterator < numberOfPages) {
        response, _ = (json)responseVector.get(pageIterator);
        numberOfRepositories = lengthof response.data.organization.repositories.nodes;
        repositoryIterator = 0;
        while(repositoryIterator < numberOfRepositories) {
            repositoryName = response.data.organization.repositories.nodes[repositoryIterator].name.toString();
            hasNextPage = "true";
            endCursor = "";
            http:OutRequest httpReq;
            http:InResponse httpResp;
            
            while(hasNextPage == "true"){
                httpReq = {};
                httpResp = {};
                httpReq.addHeader("Authorization","Bearer " + config:getGlobalValue("access_token"));
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
                httpReq.setJsonPayload(payload);
                http:HttpConnectorError  httpConnectError;
                httpResp,httpConnectError = httpGithubEP.post("",httpReq);
                if(httpConnectError != null){
                    log:printInfo("Error in post request : " + httpConnectError.message);
                }
                pullRequests = httpResp.getJsonPayload().data.organization.repository.pullRequests;
                hasNextPage = pullRequests.pageInfo.hasNextPage.toString();
                if(hasNextPage == "true"){
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
    pageIterator = 0;
    endCursor = "";
    hasNextPage = "true";

    while(pageIterator < numberOfPages) {
        response,_ = (json)responseVector.get(pageIterator);
        numberOfRepositories = lengthof response.data.organization.repositories.nodes;
        repositoryIterator = 0;
        while(repositoryIterator < numberOfRepositories) {
            repositoryName = response.data.organization.repositories.nodes[repositoryIterator].name.toString();
            hasNextPage = "true";
            endCursor = "";
            http:OutRequest httpReq;
            http:InResponse httpResp;
            while(hasNextPage=="true"){
                httpReq = {};
                httpResp = {};

                httpReq.addHeader("Authorization","Bearer "+config:getGlobalValue("access_token"));
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
                httpReq.setJsonPayload(payload);
                http:HttpConnectorError  httpConnectError;
                httpResp,httpConnectError = httpGithubClient.post("",httpReq);
                if(httpConnectError != null){
                    log:printInfo("Error in post request : " + httpConnectError.message);
                }
                issues = httpResp.getJsonPayload().data.organization.repository.issues;
                hasNextPage = issues.pageInfo.hasNextPage.toString();
                if(hasNextPage == "true"){
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
