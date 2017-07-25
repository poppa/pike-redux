//! This is the actual state in a @[Redux.Store]. The data of a @[State] object
//! can never mutate.
//!
//! @[State] objects containing a data structure of type @[mapping], @[array]
//! or @[multiset] can only be indexed on @[`[]].
//!
//! You can merge @[State] objects directly with values of the same data type
//! as the data it was instantiated with. So
//!
//! @code
//! State state_map = State(([]));
//! state_map = state_map + ([ "value" : 12 ]);
//!
//! State state_int = State(0);
//! state_int = state_int + 12;
//!
//! // ... and so on.
//! @endcode
//!
//! will all work fine.
//!
//! @fixme
//!  Document the rest...

protected typedef this_program|mapping|array|int|float|string|multiset StateType;
protected typedef mapping|array|int|float|string|multiset BuiltinType;
protected BuiltinType data;

#define IS_SAME_TYPE(A,B) (_typeof((A)) == _typeof((B)))


protected void create(BuiltinType data)
{
  this::data = data;
}


public mixed get_data()
{
  if (mappingp(data)) {
    return data + ([]);
  }

  if (arrayp(data)) {
    return data + ({});
  }

  if (multisetp(data)) {
    return data + (<>);
  }

  return data;
}


public this_program `+(StateType other)
{
  if (objectp(other)) {
    if (!is_state_object(other)) {
      error("Program to add must of type %O.\n", object_program(this));
    }

    if (!IS_SAME_TYPE(data, other->get_data())) {
      error("%O and %O don't hold the same data type.\n", this, other);
    }

    return this_program(data + other->get_data());
  }

  return this_program(data + other);
}


public this_program `-(StateType other)
{
  if (objectp(other)) {
    if (!is_state_object(other)) {
      error("Program to add must of type %O.\n", object_program(this));
    }

    if (!IS_SAME_TYPE(data, other->get_data())) {
      error("%O and %O don't hold the same data type.\n", this, other);
    }

    return this_program(data - other->get_data());
  }

  return this_program(data - other);
}


public mixed `[](mixed key)
{
  if (arrayp(data)) {
    if (!intp(key)) {
      error("Can not index array on %O.\n", _typeof(key));
    }

    return data[key];
  }

  if (mappingp(data) || multisetp(data)) {
    return data[key];
  }

  error("Unindexable data type in State.\n");
}


//! @ignore
//! NOTE! This method should not be used since it will mutate the data, but
//! it's needed for the combine_reducers to work
public mixed `[]=(mixed key, mixed value)
{
  if (arrayp(data)) {
    if (!intp(key)) {
      error("Kan not index State of array type on %O\n", _typeof(key));
    }

    return data[key] = value;
  }

  if (mappingp(data) || multisetp(data)) {
    return data[key] = value;
  }

  return data = value;
}
//! @endignore

public bool `==(StateType other)
{
  // werror("compare(%O == %O)\n", data, other);
  if (objectp(other)) {
    if (!is_state_object(other)) {
      return false;
    }

    if (!IS_SAME_TYPE(data, other->get_data())) {
      return false;
    }

    return data == other->get_data();
  }

  if (!IS_SAME_TYPE(data, other)) {
    return false;
  }

  return equal(data, other);
}


public this_program `+=(StateType other)
{
  error("A State object may not be mutated.\n");
}


protected bool is_state_object(object other)
{
  program other_prog = object_program(other);
  return this_program == other_prog ||
         Program.inherits(other_prog, this_program) ||
         Program.inherits(other_prog, Redux.State);
}

protected string _sprintf(int t)
{
  return sprintf("%O(%O)", object_program(this), data);
}

protected void destroy()
{
  data = 0;
}


/*
  Author: Pontus Östlund <https://github.com/poppa>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/
