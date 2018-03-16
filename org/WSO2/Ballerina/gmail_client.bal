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
import ballerina.util;
import ballerina.config;
import ballerina.log;

http:HttpClient httpClient = create http:HttpClient("https://www.googleapis.com/gmail", {});
http:HttpConnectorError httpConnectorError;
http:OutRequest httpRequest;
http:InResponse httpResponse;

public function send(string to,string subject, string accessToken, string message){
    endpoint<http:HttpClient> httpConnectorEP {
        httpClient;
    }
    string from = "mailapitest6@gmail.com";
    string contentType = "text/html; charset=iso-8859-1";
    string concatMessage = "";
//string cc = "engineering-group@wso2.com,rohan@wso2.com,shankar@wso2.com";
//string cc = "darsha.m3@gmail.com,vithu30@hotmail.com";
    httpRequest = {};
    httpResponse = {};
    
    concatMessage = concatMessage + "to:" + to + "\n" +
                                    "subject:" + subject + "\n" +
                                    "from:" + from + "\n" +
                                    //"cc:" + cc + "\n" +
                                    "Content-Type:" + contentType + "\n" +
                                    "\n" + message + "\n";

    string encodedRequest = util:base64Encode(concatMessage);
    encodedRequest = encodedRequest.replace("+","-");
    encodedRequest = encodedRequest.replace("/","_");
    json sendMailRequest = {"raw": encodedRequest};
    string sendMailPath = "/v1/users/" + from + "/messages/send";
    httpRequest.addHeader("Authorization", "Bearer " + accessToken);
    httpRequest.setHeader("Content-Type", "application/json");
    httpRequest.setJsonPayload(sendMailRequest);
    httpResponse, httpConnectorError = httpConnectorEP.post(sendMailPath, httpRequest);
    if(httpConnectorError != null){
        log:printInfo("Error in sending mail : " + httpConnectorError.message);
    }
}

public function generateMailBody(json pullRequests, json issues) {
    string [] productList = [];
    //string [] mailingList = [];

    productList = ["API Management","Automation","Ballerina","Cloud","Financial Solutions",
               "Identity and Access Management","Integration","IoT","Platform","Platform Extension",
                   "Research","Streaming Analytics","unknown","No build defined"];
    //mailingList = ["apim-group@wso2.com","","ballerina-group@wso2.com","cloud-group@wso2.com","",
    //"iam-group@wso2.com","integration-group@wso2.com","iot-group@wso2.com","platform-group@wso2.com",
    //"","research-group@wso2.com","analytics-group@wso2.com",""];

    string message;
    string to;
    int iterator;
    int pullRequestCount;
    int issuesCount;
    int index;
    string pullRequestMessage;
    string issueMessage;
    string product;
    //string userId;
    to = "vithursa@wso2.com";

    string accessToken = refreshAccessToken();

    string header = "<head>
                    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
                        <style>
                            table {
                                font-family: arial, sans-serif;
                                border-collapse: collapse;
                                width: 75%;
                                text-align: center;
                            }

                            td, th {
                                border: 1.5px solid #17202a;
                                text-align: left;
                                padding: 8px;
                            }
                        </style>
                    </head>";

    string prTableHeader = "<table
                                cellspacing=\"1\"
                                cellpadding=\"1\"
                                border=\"1\"
                                bgcolor=\"#F2F2F2\"
                          >
                                <tr bgcolor=\"#b4d0e8\">
                                    <th>Product</th>
                                    <th>Repository Name</th>
                                    <th>URL</th>
                                    <th>Github Id</th>
                                    <th>Open Days</th>
                                    <th>Open Weeks</th>
                                    <th>State</th>
                                </tr>";

    string issueTableHeader = "<table
                                cellspacing=\"1\"
                                cellpadding=\"1\"
                                border=\"1\"
                                bgcolor=\"#F2F2F2\"
                          >
                                <tr bgcolor=\"#b4d0e8\">
                                    <th>Product</th>
                                    <th>Repository Name</th>
                                    <th>URL</th>
                                    <th>Github Id</th>
                                    <th>Open Days</th>
                                    <th>Open Weeks</th>
                                </tr>";


    foreach str in productList {
        pullRequestCount = 0;
        issuesCount = 0;
        pullRequestMessage = "";
        issueMessage = "";

        while(iterator < lengthof pullRequests){
            product = pullRequests[iterator].product != null ? pullRequests[iterator].product.toString() :
                      "No build defined";
            if(product == str){
                pullRequestCount = pullRequestCount + 1;
                pullRequestMessage = pullRequestMessage +
                "<tr>
                    <td style=\"font-size:12px;\">" + product + "</td>
                    <td style=\"font-size:12px;\">" + pullRequests[iterator].RepositoryName.toString() + "</td>
                    <td style=\"font-size:12px;\">" + pullRequests[iterator].Url.toString() + "</td>
                    <td style=\"font-size:12px;\">" + pullRequests[iterator].githubId.toString() + "</td>
                    <td style=\"font-size:12px;\">" + pullRequests[iterator].Days.toString() + "</td>
                    <td style=\"font-size:12px;\">" + pullRequests[iterator].Weeks.toString() + "</td>
                    <td style=\"font-size:12px;\">" + pullRequests[iterator].State.toString() + "</td>
                </tr>";
            }

            iterator = iterator + 1;
        }

        iterator = 0;

        while(iterator < lengthof issues){
            product = issues[iterator].product != null ? issues[iterator].product.toString() : "No build defined";

            if(product == str){
                issuesCount = issuesCount + 1;
                issueMessage = issueMessage +
                   "<tr>
                    <td style=\"font-size:12px;\">"+product + "</td>
                    <td style=\"font-size:12px;\">" + issues[iterator].RepositoryName.toString() + "</td>
                    <td style=\"font-size:12px;\">" + issues[iterator].Url.toString() + "</td>
                    <td style=\"font-size:12px;\">" + issues[iterator].githubId.toString() + "</td>
                    <td style=\"font-size:12px;\">" + issues[iterator].Days.toString() + "</td>
                    <td style=\"font-size:12px;\">" + issues[iterator].Weeks.toString() + "</td>
                    </tr>";
            }
            iterator = iterator + 1;
        }
        iterator = 0;

        if(pullRequestCount > 0 || issuesCount > 0){
            if(checkAccessToken(accessToken)){
                accessToken = refreshAccessToken();
            }
            if(pullRequestCount > 0 && issuesCount > 0){
                message = "<html>" +
                          header +
                          "<h2>
                              \n Pull Requests from non WSO2 committers \n
                          </h2>
                          <body style=\"margin:0; padding:0;\">" +
                          prTableHeader +
                          pullRequestMessage +
                          "</table>
                          <h2>
                            \n Issues from non WSO2 committers \n
                          </h2>" +
                          issueTableHeader +
                          issueMessage +"
                          </table>
                          </body>
                          </html>";
            }
            else{
                if(pullRequestCount > 0){
                    message = "<html>" +
                              header +
                              "<h2>
                                  \n Pull Requests from non WSO2 committers \n
                              </h2>
                              <body style=\"margin:0; padding:0;\">" +
                              prTableHeader +
                              pullRequestMessage +"
                              </body>
                              </html>";
                }
                else{
                    message = "<html>"+
                              header +
                              "<h2>
                                  \n Issues from non WSO2 committers \n
                              </h2>
                              <body style=\"margin:0; padding:0;\">" +
                              issueTableHeader +
                              issueMessage +"
                              </body>
                              </html>";
                }
            }
            //to =  mailingList[index] != "" ? mailingList[index] : "vithu9330@gmail.com";
            send(to,"Open PRs and issues from non WSO2 committers : " + str,accessToken,message);
        }
        index = index + 1;
    }
}

public function checkAccessToken(string accessToken)(boolean){
    endpoint<http:HttpClient> httpConnector {
        create http:HttpClient("https://www.googleapis.com/oauth2/v1", {});
    }
    boolean isExpired = false;
    httpRequest = {};
    httpResponse = {};

    httpRequest.addHeader("Content-Type", "application/x-www-form-urlencoded");
    httpRequest.setJsonPayload("access_token=" + accessToken);
    httpResponse, httpConnectorError = httpConnector.post("/tokeninfo", httpRequest);
    if(httpConnectorError != null){
        log:printInfo("Error in checking access token : " + httpConnectorError.message);
    }
    json jsonResponse = httpResponse.getJsonPayload();
    if(jsonResponse.error_description != null) {
        isExpired = true;
    }
    return isExpired;
}

public function refreshAccessToken () (string) {
    endpoint<http:HttpClient> refreshTokenHTTPEP {
        create http:HttpClient("https://www.googleapis.com/oauth2/v4", {});
    }
    string accessToken;
    string refreshToken = config:getGlobalValue("refresh_token");
    string clientId = config:getGlobalValue("client_id");
    string clientSecret = config:getGlobalValue("client_secret");
    string request = "grant_type=refresh_token" + "&client_id=" + clientId +
                     "&client_secret=" + clientSecret +"&refresh_token=" + refreshToken;

    httpRequest = {};
    httpResponse = {};
    
    httpRequest.setHeader("Content-Type", "application/x-www-form-urlencoded");
    httpRequest.setStringPayload(request);
    httpResponse,httpConnectorError = refreshTokenHTTPEP.post("/token", httpRequest);
    if(httpConnectorError != null){
        log:printInfo("Error in generating access token : " + httpConnectorError.message);
    }
    json response = httpResponse.getJsonPayload();
    accessToken = response.access_token.toString();
    return accessToken;
}