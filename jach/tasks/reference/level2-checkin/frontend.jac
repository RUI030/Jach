"""Render and update the check-in sheet."""

import from server { Person, list_people, check_in }

"""Show each person's stored status and provide a check-in button."""
def:pub app -> JsxElement {
    has people: list[Person] = [];

    async can with entry {
        people = await list_people();
    }

    async def check_person(name: str) {
        await check_in(name);
        people = await list_people();
    }

    <div>
        <h1>Check-in sheet</h1>
        <table>
            <tbody>
                {for person in people {
                    <tr key={person.name}>
                        <td>{person.name}</td>
                        <td>{person.name + (": present" if person.present else ": absent")}</td>
                        <td><button onClick={lambda (_e: MouseEvent) { check_person(person.name); }}>{"Check in " + person.name}</button></td>
                    </tr>
                }}
            </tbody>
        </table>
    </div>
}
