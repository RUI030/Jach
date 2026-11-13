"""Store and update check-in people in the root graph."""

"""Represent one person's name and attendance status."""
node Person {
    has name: str;
    has present: bool = False;
}

"""Return the three persistent people, creating them on the first request."""
def:pub list_people -> list[Person] {
    people = [root -->][?:Person];
    if len(people) == 0 {
        root ++> Person(name="Ada");
        root ++> Person(name="Ben");
        root ++> Person(name="Cy");
        people = [root -->][?:Person];
    }
    return people;
}

"""Mark the named person present in the persistent graph."""
def:pub check_in(name: str) -> None {
    for person in [root -->][?:Person] {
        if person.name == name {
            person.present = True;
            return;
        }
    }
}
