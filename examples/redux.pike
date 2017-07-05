//! Global storage
Redux.Store store;

//! Implements @[Redux.Action]
private class action(string type, int payload) {
  string _sprintf(int t) {
    return sprintf("(%O => %O)", type, payload);
  }
}

//! The reducer function will be called everytime an action is dispatched
//! on the @[store]. If the state is not of a primitive type a new copy
//! of the state must be returned form the reducer.
Redux.State reducer(Redux.State state, Redux.Action action)
{
  Redux.State new_state;

  // This is also a way of creating the default state
  if (action->type == Redux.ActionType.INIT) {
    return state || ([]);
  }

  if (action->type == "inc") {
    // Given that we use a mapping as State. In this particular case we
    // could have used an int as State, but this is more to show the
    // purpose of not mutating a State if it is of a reference type.
    new_state = state + ([ "value" : state->value + action->payload ]);
  }
  else if (action->type == "dec") {
    new_state = state + ([ "value" : state->value - action->payload ]);
  }

  //! If no new state was created, return the original one. If we never
  //! touched it it couldn't have been mutated.
  return new_state || state;
}

int main(int argc, array(string) argv)
{
  // Initialize a new store with an empty mapping as default State.
  store = Redux.create_store(reducer, ([]));

  // Subscribe for changes
  Redux.Subscriber listener = store->subscribe(lambda() {
    werror("State was changed: %O\n", store->state);
  });

  // This will only be called once since it removes it self after the first
  // notification.
  store->subscribe(lambda() {
    werror("I say this once: State was changed: %O\n", store->state);
    store->unsubscribe(this_function);
  });

  // Now let's dispatch some actions.
  store->dispatch(action("inc",   4));
  store->dispatch(action("inc",   8));
  store->dispatch(action("dec",  10));

  // The reducer function above doesn't take actions of type "skip"
  // into consideration, but the listener will get notified nonetheless.
  store->dispatch(action("skip", 104));

  write("The result of the state is: %d\n", store->state->value);

  return 0;
}
