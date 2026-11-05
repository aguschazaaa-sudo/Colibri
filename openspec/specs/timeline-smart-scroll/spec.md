## ADDED Requirements

### Requirement: Auto-scroll al primer turno para días que no son hoy
Cuando `DayTimelineView` se renderiza con `isToday: false` y la lista de items no está vacía, el timeline SHALL hacer auto-scroll al primer turno del día, posicionando el viewport con un margen de ~30 minutos por encima del primer turno.

#### Scenario: Día pasado con turnos hace scroll al primero
- **WHEN** el usuario navega a un día pasado que tiene turnos a partir de las 10:00
- **THEN** el timeline hace scroll para que las ~09:30 queden en la parte superior del viewport

#### Scenario: Día futuro con turnos hace scroll al primero
- **WHEN** el usuario navega a un día futuro que tiene turnos a partir de las 14:00
- **THEN** el timeline hace scroll para que las ~13:30 queden en la parte superior del viewport

#### Scenario: Día sin turnos no hace scroll
- **WHEN** el usuario navega a un día que no tiene turnos
- **THEN** el timeline se muestra desde el inicio sin auto-scroll

#### Scenario: Cambio de día re-ejecuta el scroll
- **WHEN** el usuario cambia de un día a otro (ambos no-hoy)
- **THEN** el timeline hace scroll al primer turno del nuevo día
