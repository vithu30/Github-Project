package APIs;

import ballerina.net.http;
import ballerina.collections;

public function getRepositories () (collections:Vector) {
    endpoint <http:HttpClient> httpGithubClient {
        create http:HttpClient ("https://api.github.com/graphql",{});
    }

    string endCursor="";
    string hasNextPage = "true";
    string QUERY;
    collections:Vector responseVector = {vec:[]};


    while(hasNextPage=="true"){
        http:OutRequest httpRequest ={};
        http:InResponse httpResponse = {};
        QUERY = string `{
                      organization(login:\\\"wso2\\\") {
                        id
                        name
                        url
                        repositories(first: 100,after:{{endCursor}}) {
                          pageInfo {
                            hasNextPage
                            endCursor
                          }
                          totalCount
                          nodes {
                            id
                            name
                          }
                        }
                      }
                      }
                    `;


        httpRequest.addHeader("Authorization","Bearer "+TOKEN);
        json jsonPayLoad = {query:QUERY};
        httpRequest.setJsonPayload(jsonPayLoad);

        http:HttpConnectorError httpConnectionError;
        httpResponse, httpConnectionError = httpGithubClient.post("", httpRequest);
        json response = httpResponse.getJsonPayload();
        responseVector.add(response);
        endCursor = "\\\"" +response.data.organization.repositories.pageInfo.endCursor.toString() +"\\\"";
        hasNextPage = response.data.organization.repositories.pageInfo.hasNextPage.toString();
    }
    return responseVector;
}

public function getData(){
    endpoint <http:HttpClient> httpGithubClient {
        create http:HttpClient ("https://api.github.com/graphql",{});
    }

    collections:Vector responseVector = getRepositories();
    int iterator1;
    int iterator2;
    json response;
    string repositoryName;
    int count;
    while(iterator1<responseVector.vectorSize){
        response,_ = (json)responseVector.get(iterator1);
        iterator2 = 0;
        while(iterator2<lengthof response.data.organization.repositories.nodes){
            count = count +1;
            repositoryName = response.data.organization.repositories.nodes[iterator2].name.toString();
            http:OutRequest httpReq = {};
            http:InResponse httpResp = {};

            httpReq.addHeader("Authorization","Bearer "+TOKEN);

            string QUERY = string `{
                  organization(login:\\\"wso2\\\") {
                    repository(name:\\\"{{repositoryName}}\\\") {
                      pullRequests(first:50, states:[OPEN]) {
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

                    issues(first:50, states:[OPEN]) {

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
                }

                `;

            json payload = {query:QUERY};
            httpReq.setJsonPayload(payload);
            http:HttpConnectorError  httpConnectError;
            httpResp,httpConnectError = httpGithubClient.post("",httpReq);
            filterPullRequests(httpResp.getJsonPayload());
            filterIssues(httpResp.getJsonPayload());
            iterator2 = iterator2 +1;
        }
        iterator1 = iterator1 +1;
    }
}