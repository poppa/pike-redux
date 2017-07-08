
//! Implements @[Redux.Action]
private class action(string type, int payload) {
  string _sprintf(int t) {
    return sprintf("(%O => %O)", type, payload);
  }
}


//! Do we call this IICE?
object my_actions = class {
  constant INC = "inc";
  constant DEC = "dec";

  Redux.Action inc(int payload) {
    return action(INC, payload);
  }

  Redux.Action dec(int payload) {
    return action(DEC, payload);
  }
}();


int main(int argc, array(string) argv)
{
  Redux.Reducer reducers = Redux.combine_reducers(([
    "key1" : reducer1,
    "key2" : reducer2
  ]));

  Redux.Store store = Redux.create_store(reducers, ([ "key1" : 0, "key2": 0 ]));

  // Bind multiple creators via a class instance
  mapping(string:Redux.ActionFunction) action =
    Redux.bind_action_creators(my_actions, store->dispatch);

  action->inc(12);
  action->dec(5);

  werror(">>> Result State: %O\n", store->state);

  return 0;
}


Redux.State reducer1(Redux.State state, Redux.Action action)
{
  switch (action->type)
  {
    case "inc":
      state = state + action->payload;
      break;

    case "dec":
      state = state - action->payload;
      break;
  }

  return state;
}


Redux.State reducer2(Redux.State state, Redux.Action action)
{
  switch (action->type)
  {
    case "inc":
      state = state + action->payload*2;
      break;

    case "dec":
      state = state - action->payload*2 ;
      break;
  }

  return state;
}
