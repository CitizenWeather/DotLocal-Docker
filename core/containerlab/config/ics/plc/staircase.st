PROGRAM StaircaseController
VAR
    Floor1_Sensor : BOOL;   (* physical input *)
    Floor2_Sensor : BOOL;
    Floor1_Light : BOOL;    (* output *)
    Floor2_Light : BOOL;
    TimerON : TON;
END_VAR

(* Ladder logic equivalent: light turns on for 30s after sensor *)
TimerON(IN := Floor1_Sensor OR Floor2_Sensor, PT := T#30s);
Floor1_Light := TimerON.Q AND Floor1_Sensor;
Floor2_Light := TimerON.Q AND Floor2_Sensor;

END_PROGRAM