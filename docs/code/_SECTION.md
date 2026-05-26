## Policy as Code -- Network Wide 

A single declarative policy language describing:

Who can talk to whom (network policy)
Who can register what (registrar policy)
What egress is allowed (gateway policy)
What identity claims are honoured (auth policy)

Suggested: OPA / Rego, or Cedar. The whole localnet enforces one coherent policy graph. This is genuinely ahead of 
where most enterprises are today.