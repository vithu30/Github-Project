package APIs;
import ballerina.data.sql;
import ballerina.net.http;
import ballerina.util;
import ballerina.config;


public function sendMail(string message,string to,string subject,string accessToken){


    endpoint<http:HttpClient> httpConnectorEP {
        create http:HttpClient("https://www.googleapis.com/gmail", {});
    }
    string from = "mailapitest6@gmail.com";
    string contentType = "text/html; charset=iso-8859-1";
    //string cc = "pmc-group@wso2.com,rohan@wso2.com,shankar@wso2.com";
    //string cc = "darsha.m3@gmail.com,vithu30@hotmail.com";

    string messageBody = message;

    http:OutRequest request = {};
    http:InResponse response = {};
    string concatRequest = "";

        concatRequest = concatRequest + "to:" + to + "\n";

        concatRequest = concatRequest + "subject:" + subject + "\n";

        concatRequest = concatRequest + "from:" + from + "\n";

        //concatRequest = concatRequest + "cc:" + cc + "\n";

        concatRequest = concatRequest + "Content-Type:" + contentType + "\n";

        concatRequest = concatRequest + "\n" + messageBody + "\n";

    string encodedRequest = util:base64Encode(concatRequest);
    encodedRequest = encodedRequest.replace("+","-");
    encodedRequest = encodedRequest.replace("/","_");
    json sendMailRequest = {"raw": encodedRequest};
    string sendMailPath = "/v1/users/" + from + "/messages/send";
    request.addHeader("Authorization","Bearer "+accessToken);
    request.setHeader("Content-Type", "application/json");
    request.setJsonPayload(sendMailRequest);
    response,_ = httpConnectorEP.post(sendMailPath,request);
}

public function generateMessage () {
    endpoint<sql:ClientConnector> testDB {
        create sql:ClientConnector(
        sql:DB.MYSQL, "localhost", 3306, "FilteredData", config:getGlobalValue("username"), config:getGlobalValue("password"), {maximumPoolSize:5,url:"jdbc:mysql://localhost:3306/FilteredData?useSSL=false"});
    }

    string accessToken = refreshAccessToken();

    boolean flag = true;
    string [] productList = [];
    string [] mailingList = [];
    productList = ["API Management","Automation","Ballerina","Cloud","Financial Solutions",
                   "Identity and Access Management","Integration","IoT","Platform","Platform Extension","
                   Research","Streaming Analytics","unknown"];
    //mailingList = ["apim-group@wso2.com",];


    sql:Parameter repoName;
    sql:Parameter url;
    sql:Parameter githubId;
    sql:Parameter duration;
    sql:Parameter[] params = [repoName, url, githubId, duration];
    int countPRs;
    int countIssues;

    string messageBody;
    string header;

    string tableHeader1;
    string tableHeader2;

    header = "<head>
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

        tr:nth-child(odd) {
            background-color: black;
        }
    </style>
</head>";

    tableHeader1 = "<table>
    <tr bgcolor=\\\"white\\\">
        <th><font color=\\\"#FFFFFF\\\">Product</th>
        <th><font color=\\\"#FFFFFF\\\">Repository Name</th>
        <th><font color=\\\"#FFFFFF\\\">Pull Request URL</th>
        <th><font color=\\\"#FFFFFF\\\">Github Id</th>
        <th><font color=\\\"#FFFFFF\\\">Open Days</th>
        <th><font color=\\\"#FFFFFF\\\">Open Weeks</th>
    </tr>";

    tableHeader2 = "<table>
    <tr bgcolor=\\\"white\\\">
        <th><font color=\\\"#FFFFFF\\\">Product</th>
        <th><font color=\\\"#FFFFFF\\\">Repository Name</th>
        <th><font color=\\\"#FFFFFF\\\">Issue URL</th>
        <th><font color=\\\"#FFFFFF\\\">Github Id</th>
        <th><font color=\\\"#FFFFFF\\\">Open Days</th>
        <th><font color=\\\"#FFFFFF\\\">Open Weeks</th>
    </tr>";

        table prData = testDB.select("SELECT * FROM pullRequests INNER JOIN product ON
    pullRequests.RepositoryName = product.RepoName ",null,null);
        var prRes, err = <json>prData;
        int i;
        int j;
        foreach str in productList  {
            string body1 = "";
            while(i<lengthof prRes){
                if(prRes[i].Product.toString()==str){
                    countPRs = countPRs + 1;
                    body1 = body1 + "<tr>
                                <td>"+prRes[i].Product.toString()+"</td>
                                <td>"+prRes[i].RepositoryName.toString()+"</td>
                                <td>"+ prRes[i].PullUrl.toString()+"</td>
                                <td>"+prRes[i].githubId.toString()+"</td>
                                <td>"+prRes[i].Days.toString()+"</td>
                                <td>"+prRes[i].Weeks.toString()+"</td>
                                </tr>";
                }
                i=i+1;
            }
            body1 = body1 +"</table>";

            table issueData = testDB.select("SELECT * FROM issues INNER JOIN product ON
    issues.RepositoryName = product.RepoName ",null,null);
            var issueRes, err = <json>issueData;
            string body2 = "";
            while(j<lengthof issueRes){
                if(issueRes[j].Product.toString()==str){
                    string github = issueRes[j].githubId!= null ? issueRes[j].githubId.toString() : "null";
                    countIssues = countIssues + 1;
                    body2 = body2 + "<tr>
                                <td>"+issueRes[j].Product.toString()+"</td>
                                <td>"+issueRes[j].RepositoryName.toString()+"</td>
                                <td>"+issueRes[j].IssueUrl.toString()+"</td>
                                <td>"+github+"</td>
                                <td>"+issueRes[j].Days.toString()+"</td>
                                <td>"+issueRes[j].Weeks.toString()+"</td>
                                </tr>";
                }
                j=j+1;
            }
            j=0;
            i = 0;
            body2 = body2 + "</table>";

            if(countPRs >0 || countIssues>0) {
                if(checkAccessToken(accessToken)){
                    accessToken = refreshAccessToken();
                }
                if(countPRs>0 && countIssues>0){
                    messageBody = "<html>"+header+"<body><h2 style=\"font-family:Courier New;\">\n Pull Requests from non WSO2 committers \n</h2>"+tableHeader1+body1+"<h2 style=\"font-family:Courier New;\">\n Issues from non WSO2 committers \n</h2>"+tableHeader2+body2+"</body></html>";

                }
                else{
                    if(countPRs>0){
                        messageBody = "<html>"+header+"<body><h2 style=\"font-family:Courier New;\">\n Pull Requests from non WSO2 committers \n</h2>"+tableHeader1+body1+"</body></html>";
                    }
                    else{
                        messageBody = "<html>"+header+"<body><h2 style=\"font-family:Courier New;\">\n Issues from non WSO2 committers \n</h2>"+tableHeader2+body2+"</body></html>";
                    }

                }
                sendMail(messageBody, "vithursa@wso2.com","Open PRs and issues from non WSO2 committers",accessToken);
                println("sending pr mail");
                countIssues = 0;
                countPRs = 0;
            }
        }
    int ret = testDB.update("DELETE FROM pullRequests",null);
    ret = testDB.update("DELETE FROM issues",null);
    testDB.close();
    return ;
}

public function checkAccessToken(string accessToken)(boolean){
    endpoint<http:HttpClient> httpConnector {
        create http:HttpClient("https://www.googleapis.com/oauth2/v1", {});
    }
    boolean isExpired = false;
    http:OutRequest tokenReq = {};
    http:InResponse tokenResp = {};

    tokenReq.addHeader("Content-Type","application/x-www-form-urlencoded");
    tokenReq.setJsonPayload("access_token="+accessToken);
    tokenResp,_ = httpConnector.post("/tokeninfo",tokenReq);
    json resp = tokenResp.getJsonPayload();
    if(resp.error_description!=null){
        isExpired = true;
    }
    return isExpired;
}

public function refreshAccessToken () (string) {
    endpoint<http:HttpClient> refreshTokenHTTPEP {
        create http:HttpClient("https://www.googleapis.com/oauth2/v4", {});
    }
    string accessToken;
    http:OutRequest refreshTokenRequest = {};
    http:InResponse refreshTokenResponse = {};

    string refreshToken = config:getGlobalValue("refresh_token");
    string clientId = config:getGlobalValue("client_id");
    string clientSecret = config:getGlobalValue("client_secret");

    string request = "grant_type=refresh_token"+"&client_id="+clientId+"&client_secret="+clientSecret+"&refresh_token="+refreshToken;
    refreshTokenRequest.setStringPayload(request);
    refreshTokenRequest.setHeader("Content-Type", "application/x-www-form-urlencoded");
    refreshTokenResponse,_ = refreshTokenHTTPEP.post("/token", refreshTokenRequest);
    json response = refreshTokenResponse.getJsonPayload();
    accessToken = response.access_token.toString();
    return accessToken;
}
