# Interview Exercise – Exact Requirements
Source: email from Yaniv (screenshot 2026-11-12 15:56)

## General
1. Please advise when you will answer all questions.
2. If you use CHAT GPT or other AI please write that.

## Exercise 1
1. You need to provision a new "hello world" with Web application a little apples :) page
2. This is a simple page
3. The architecture should include: NodeJS, MongoDB, Containers.
4. The runtime should be on any Linux distro you prefer
5. Every component of the architecture should run in its own container
6. All the architecture should be fully defined by scripts and code (IaC) saved in github
7. The DB should contain this data:
   ```json
   [
     { "_id": 1, "name": "apples",   "qty": 5, "rating": 3 },
     { "_id": 2, "name": "bananas",  "qty": 7, "rating": 1, "microsieverts": 0.1 },
     { "_id": 3, "name": "oranges",  "qty": 6, "rating": 2 },
     { "_id": 4, "name": "avocados", "qty": 3, "rating": 5 }
   ]
   ```
8. The exercise submission should be a git repo with all the scripts and automation code to provision the architecture.
9. The exercise will be checked by running the scripts in the submitted repo.
10. Tests that the exercise should pass:
    - Provision from scratch of the entire architecture
    - The html page returns the number of apples in the DB
    - Visual demonstration of the architecture (containers, network topology etc..)
11. Bonus
    - Full ci/cd pipeline with one of the cloud providers
    - Readme page in the git repo with guide that explains about the app, architecture design etc..
    - Load balancer
    - Your own ideas will be welcome - create a PULL REQUEST to this branch :)
12. At the end of the exercise you will be asked about the architecture design and the components to demonstrate your ability to learn and understand new areas and technology.

Thanks,
Yaniv
