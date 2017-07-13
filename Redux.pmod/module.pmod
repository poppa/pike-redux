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

//! Typedef for the mapping of @[Reducer]s passed as argument to
//! @[combine_reducers()]
typedef mapping(string:Reducer) ReducerMap;

//! Typedef of an enhancer function
typedef function(typeof(create_store):function(Reducer,State:.Store)) Enhancer;

//! Typedef for a subscriber function
typedef function(.Store|void, Action|void : void) Subscriber;

//! Typedef for a function returned from @[compose()]
typedef function(mixed : function) Composition;

//! Typedef for an action function returned from @[bind_action_creator] or
//! @[bind_action_creators]
typedef function(mixed... : Action) ActionFunction;

//! Typedef for the function returned from @[bind_action_creator]
typedef function(mixed... : ActionFunction) ActionCreator;

//! Typedef for the mapping of function passed as argument to
//! @[bind_action_creators]
typedef object|program ActionCreatorObject;


//! Creates a new @[.Store] instance.
//!
//! @param reducer
//! @param init_state
//! @param enhancer
.Store create_store(Reducer reducer,
                    State init_state,
                    void|Enhancer enhancer)
{
  if (enhancer) {
    return enhancer(create_store)(reducer, init_state);
  }

  .Store store = .Store(reducer, init_state);

  return store;
}


//! Bind an action creator function to @[.Store->dispatch()].
//!
//! @seealso
//!  @[bind_action_creators()]
//!
//! @param func
//! @param dispatch
ActionFunction bind_action_creator(ActionCreator func,
                                   function dispatch)
{
  return lambda (mixed ... args) {
    return dispatch(func(@args));
  };
}

//! Bind multiple actions creators to a single mapping.
//!
//! @seealso
//!  @[bind_action_creator()]
//!
//! @param action_creator
//! @param dispatch
mapping(string:ActionFunction)
bind_action_creators(ActionCreatorObject action_creator,
                     function dispatch)
{
  array(mixed) keys = indices(action_creator);
  mapping(string:ActionFunction) bound_creators = ([]);

  object creator_instance;

  if (programp(action_creator)) {
    creator_instance = action_creator();
  }
  else {
    creator_instance = action_creator;
  }

  foreach (indices(creator_instance), string name) {
    if (functionp(creator_instance[name])) {
      bound_creators[name] =
        bind_action_creator(creator_instance[name], dispatch);
    }
  }

  return bound_creators;
}

//! Combine reducers
//!
//! @param reducers
Reducer combine_reducers(ReducerMap reducers)
{
  ReducerMap final_reducers = reducers + ([]);

  return lambda (State state, Action action) {
    bool has_changed = false;
    state = state || ([]);
    mapping next_state = ([]);

    foreach (final_reducers; string key; Reducer reducer) {
      mixed previous_state_for_key = state[key];
      mixed next_state_for_key = reducer(previous_state_for_key, action);

      next_state[key] = next_state_for_key;
      has_changed = has_changed || (next_state_for_key != previous_state_for_key);
    }

    return has_changed ? next_state : state;
  };
}

//! Compose an array of functions to a new function which when called will call
//! the @[args] function is sequence right to left
//!
//! @param args
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
