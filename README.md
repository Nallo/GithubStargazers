# GithubStargazers

Given a Github user and its repository name displays the repository's stargazers.

## Architecture Diagram

![Architecture Diagram](Architecture.jpg)

## Limitations

 - Max 60 requests per hour. App uses Github unauthenticated APIs.
 - Max 30 stargazers displayed. App does not implement Github APIs pagination.