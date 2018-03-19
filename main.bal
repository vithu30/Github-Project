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

import org.WSO2.Ballerina;
import ballerina.collections;
import ballerina.log;

function main (string[] args) {
    log:printInfo("Prgram initiated");
    collections:Vector reposVector = Ballerina:getRepositories();
    Ballerina:getPullRequests(reposVector);
    Ballerina:getIssues(reposVector);
    Ballerina:writeRawData();
    log:printInfo("successfully wrote to database");
    json pullRequests = Ballerina:readData("pullRequests");
    json issues = Ballerina:readData("issues");
    log:printInfo("read filtered data from database");
    Ballerina:generateMailBody(pullRequests,issues);
    log:printInfo("mail sending success");
}
