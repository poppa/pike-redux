
class action(string type, int payload) {
  string _sprintf(int t) {
    return sprintf("%O(%O => %O)", object_program(this), type, payload);
  }
}

class my_actions {
  constant INC = "inc";
  constant DEC = "dec";
  constant INC2 = "inc2";
  constant DEC2 = "dec2";

  Redux.Action inc(int payload) {
    return action(INC, payload);
  }

  Redux.Action dec(int payload) {
    return action(DEC, payload);
  }

  Redux.Action inc2(int payload) {
    return action(INC2, payload);
  }

  Redux.Action dec2(int payload) {
    return action(DEC2, payload);
  }
}

mapping store;
mapping actions;

Redux.State reducer1(Redux.State state, Redux.Action action)
{
  // if (action->type == Redux.REDUX_INIT) {
  //   return ([ "val" : 0 ]);
  // }

  switch (action->type)
  {
    case "inc":
      state = state + ([ "val" : state->val + action->payload ]);
      break;

    case "dec":
      state = state + ([ "val" : state->val - action->payload ]);
      // actions->inc(4);
      break;
  }

  return state;
}

Redux.State reducer2(Redux.State state, Redux.Action action)
{
  // if (action->type == Redux.ActionType.INIT) {
  //   return ([ "val" : 0 ]);
  // }

  switch (action->type)
  {
    case "inc2":
      state = state + ([ "val" : state->val + action->payload ]);
      break;

    case "dec2":
      state = state + ([ "val" : state->val - action->payload ]);
      // actions->inc(4);
      break;
  }

  return state;
}


int main(int argc, array(string) argv)
{
  mapping init_state = ([
    "key1": ([ "val" : 0]),
    "key2": ([ "val" : 0])
  ]);

  function combo = Redux.combine_reducers(([
    "key1": reducer1,
    "key2": reducer2
  ]));

  store = Redux.create_store(combo, Redux.State(init_state));
  actions = Redux.bind_action_creators(my_actions, store->dispatch);

  function unsubscribe =
    store->subscribe(lambda (Redux.Action a) {
      werror(">>> Subscriber called: %O\n", a);
    });

  actions->inc(12);
  actions->dec(7);
  actions->inc(3);
  unsubscribe();
  actions->dec2(7);
  actions->inc2(3);

  werror("Result: %O\n", store->get_state());

  return 0;
}
