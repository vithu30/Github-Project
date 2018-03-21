package org.WSO2.Ballerina;

public const string FIRST_PAGE_REPOSITORY_QUERY = "query ($login: String!){
                                                        organization(login:$login) {
                                                            repositories(first: 100) {
                                                                pageInfo {
                                                                    hasNextPage
                                                                    endCursor
                                                                }
                                                                nodes {
                                                                    name
                                                                }
                                                            }
                                                        }
                                                    }";

public const string NEXT_PAGE_REPOSITORY_QUERY = "query ($login: String!,$endCursor: String!){
                                                        organization(login:$login) {
                                                            repositories(first: 100, after:$endCursor) {
                                                                pageInfo {
                                                                    hasNextPage
                                                                    endCursor
                                                                }
                                                                nodes {
                                                                    name
                                                                }
                                                            }
                                                        }
                                                    }";

public const string FIRST_PAGE_PULL_REQUEST_QUERY = "query ($login: String!,$repositoryName:String!){
                                                        organization(login:$login) {
                                                            repository(name:$repositoryName){
                                                                pullRequests(first:100, states:[OPEN]) {
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
                                                    }";



public const string NEXT_PAGE_PULL_REQUEST_QUERY = "query ($login: String!,$repositoryName:String!,$endCursor:String!){
                                                        organization(login:$login) {
                                                            repository(name:$repositoryName){
                                                                pullRequests(first:100, states:[OPEN],after:$endCursor) {
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
                                                    }";

public const string FIRST_PAGE_ISSUE_QUERY = "query ($login: String!,$repositoryName:String!){
                                                        organization(login:$login) {
                                                            repository(name:$repositoryName){
                                                                issues(first:100, states:[OPEN]) {
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
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }";

public const string NEXT_PAGE_ISSUE_QUERY = "query ($login: String!,$repositoryName:String!,$endCursor:String!){
                                                        organization(login:$login) {
                                                            repository(name:$repositoryName){
                                                                issues(first:100, states:[OPEN],after:$endCursor) {
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
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }";
