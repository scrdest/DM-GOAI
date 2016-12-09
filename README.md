# DM-GOAI
An experiment in coding a modern-style Goal-Oriented Action Programming (GOAP) NPC AI in BYOND's DM language.

---
What is GOAP?


GOAP is a really quite clever method for extensible AI code first described by Jeff Orkin who implemented it for FEAR and Condemned: Criminal Origins. It uses a very barebones Finite State Machine (FSM) and instead of relying on expanding that FSM with new behaviors, it uses a generic PerformAction state to access all behavior modules (actions).

Each action has a set of requirements (preconditions) and effects. The AI is trying to meet its arbitrary goals by performing an action that meets the goal. This is accomplished by building plans which are then evaluated with A*. If the action could accomplish the goal but its requirements are not met, the algorithm attempts to find out if an action with an effect fulfilling that requirement could be found among the available actions recursively and if it does, the action is added to the complete plan to accomplish a goal.

As mentioned before, the plans are then evaluated with A* to pick a solution, taking in account the actor's motive costs and gains from the action and the best action is executed.

I recommend Orkin's 'Three States and a Plan: The A.I. of F.E.A.R.' if you want to read a more in-depth explanation by an actual CS PhD rather than some rando on the internet.

---

So wait, are those SNPCs?


Nope, this is more or less completely unrelated to SNPCs. For that matter, it isn't even necessarily written for SS13 although this was how I planned to use it myself.
