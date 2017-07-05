//! Redux is a predictable state container originally written for JavaScript
//! apps. This is a Pike implementation of that state container. For more
//! info on the original implementation see
//! @url{https://github.com/reactjs/redux@}.
//!
//! @example
//! @code
//! //! Global storage
//! Redux.Store store;
//!
//! //! Implements @[Redux.Action]
//! private class action(string type, int payload) {
//!   string _sprintf(int t) {
//!     return sprintf("(%O => %O)", type, payload);
//!   }
//! }
//!
//! //! The reducer function will be called everytime an action is dispatched
//! //! on the @[store]. If the state is not of a primitive type a new copy
//! //! of the state must be returned form the reducer.
//! Redux.State reducer(Redux.State state, Redux.Action action)
//! {
//!   Redux.State new_state;
//!
//!   // This is also a way of creating the default state
//!   if (action->type == Redux.ActionType.INIT) {
//!     return state || ([]);
//!   }
//!
//!   if (action->type == "inc") {
//!     // Given that we use a mapping as State. In this particular case we
//!     // could have used an int as State, but this is more to show the
//!     // purpose of not mutating State of reference type.
//!     new_state = state + ([ "value" : state->value + action->payload ]);
//!   }
//!   else if (action->type == "dec") {
//!     new_state = state + ([ "value" : state->value - action->payload ]);
//!   }
//!
//!   //! If no new state was created, return the original one. If we never
//!   //! touched it it couldn't have been mutated.
//!   return new_state || state;
//! }
//!
//! int main(int argc, array(string) argv)
//! {
//!   // Initialize a new store with an empty mapping as default State.
//!   store = Redux.create_store(reducer, ([]));
//!
//!   // Subscribe for changes
//!   Redux.Subscriber listener = store->subscribe(lambda() {
//!     werror("State was changed: %O\n", store->state);
//!   });
//!
//!   Redux.Subscriber once = store->subscribe(lambda() {
//!     werror("I say this once: State was changed: %O\n", store->state);
//!     store->unsubscribe(this_function);
//!   });
//!
//!   // Now let's dispatch some actions.
//!
//!   store->dispatch(action("inc",   4));
//!   store->dispatch(action("inc",   8));
//!   store->dispatch(action("dec",  10));
//!   // The reducer function above doesn't take actions of type "skip"
//!   // into consideration, but the listener will get notified nonetheless.
//!   store->dispatch(action("skip", 104));
//!
//!   write("The result of the state is: %d\n", store->state->value);
//!
//!   return 0;
//! }
//! @endcode

class ActionType {
  constant INIT = "@@redux/INIT";
}

//! Action prototype. Implement like
//!
//! @code
//! class MyAction(string type, mixed payload){}
//! @endcode
class Action(string type){}


//! Typedef of a state
typedef object|string(8bit)|mapping|array|int|float|multiset State;

//! Typedef for a reducer function
typedef function(State, Action : State) Reducer;

//! Typedef of an enhancer function
typedef function(typeof(create_store):function(Reducer,State:.Store)) Enhancer;

typedef function(.Store|void : void) Subscriber;

typedef function(mixed... : mixed) Composition;

typedef function(mixed... : Action) ActionFunction;
typedef function|mapping|object ActionCreator;
// typedef function|mapping ActionFunction;

typedef function(mixed... : ActionFunction) ActionCreatorFunction;

typedef object ActionCreatorObject;


.Store create_store(Reducer       reducer,
                    void|State    init_state,
                    void|Enhancer enhancer)
{
  if (enhancer) {
    return enhancer(create_store)(reducer, init_state);
  }

  .Store store = .Store(reducer, init_state);

  return store;
}



ActionFunction bind_action_creator(ActionCreatorFunction func,
                                   function dispatch)
{
  return lambda (mixed ... args) {
    return dispatch(func(@args));
  };
}

mapping(string:ActionFunction)
bind_action_creators(ActionCreatorObject action_creator,
                     function dispatch)
{
  array(mixed) keys = indices(action_creator);
  mapping(string:ActionFunction) bound_creators = ([]);

  foreach (indices(action_creator), string name) {
    if (functionp(action_creator[name])) {
      bound_creators[name] = bind_action_creator(action_creator[name], dispatch);
    }
  }

  return bound_creators;
}


Composition compose(function ... args)
{
  if (!sizeof(args)) {
    return lambda (mixed arg) {
      return arg;
    };
  }

  if (sizeof(args) == 1) {
    return args[0];
  }

  return Array.reduce(lambda (function a, function b) {
    return lambda (mixed ... args) {
      return a(b(@args));
    };
  }, args);
}
