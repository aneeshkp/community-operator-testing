# community-operator-testing
operator.sh
The script creates folder tigeroperators in your home directory and then pull the repo and fetch  your pulkl request , making it available for testing
(use dot dot/operator.sh to run in same shell)
Usage: . ./operator.sh 


Example: 
./operator.sh 
```
select operator setup option or test command

        PROGRAM MENU
        1 - Operator Setup
        2 - Print testing commands

```
Option one will create git hub folder and fettch the pull request , access qauy token and generate operator courier to lint the operator

```
Enter your selection (1/2): 1

Select operator type 1=comunity 2=upstream for  fetching PR.

        CHOOSE OPERATOR TYPE
        -----------------------------
        1 - Community Operators
        2 - Upstream Community Operators
        -----------------------------
    
----------------------------
Select Operator Type (1/2): 
----------------------------
Select Operator Type (1/2): 1

You selectd operator type as community-operators
OPERATOR NAME:enmasse
Enter Pull ID
371
Enter Branch name (The branch name you want to create):
mytest
```



