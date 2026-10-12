# Design System: Scrypath Operator UI

## Overview

The operator interface puts the current search observation first, then offers a safe next action. In the Control Room, `ControlRoomLive` owns a labelled health section and composes shared `OpsUi` pieces: a refresh-incomplete notice, a verdict, and intent cards for Search health, sync and drift, or Search. The selected content follows the observation; the page does not force every route into one generic card layout.

This description follows the rendered implementation and the token catalog. Keep each screen's operator task and evidence order intact, use shared components when their semantics fit, and keep operational status explicit in text rather than relying on color or decoration.
