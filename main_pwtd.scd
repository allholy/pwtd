//Written by Panagiota Anastasopoulou
//21-05-13
//PLay with the dust

//load initializations
"init_pwtd.scd".loadRelative;

// Performance - way 1
//press ctrl+enter to move forward to the structure of the piece
//10 parts (+1 to stop all)
(
~structure[~count].value;
~count = ~count +1;
)
s.record("~/Desktop/play_with_the_dust3.wav");
~count = 0; //restart piece if necessary


//Warning:
//Run the code with your own risk. The behavior that has in my computer may differ at another.