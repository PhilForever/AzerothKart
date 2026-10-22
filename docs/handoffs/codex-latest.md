# Codex handoff — painted Stormwind wall alignment installed

2026-10-22 10:46 +02:00, Europe/Oslo. Owner reports an invisible collisionwall at the Park/Mage innerpavedcorner before the whitewaterparapet. Implemented/installed **81cc0ed69da79d0ea5dcb03d2c5af924afcf100e** on **codex/stormwind-wall-alignment**, from clean installedf62e708. Followingdocscommit records deployment; no addon changes after testedcommit. Reservation preceded source edits; no otheragentcheckout/history overwritten, publication/mainmerge/release/clientautomation.

## Diagnosis / implementation

ActualLua repro(442,849)→(445,846) returnedstart/hit; (450,850)classifiedwall despitewhiteexposedapex(476.265215329,866.369426623) over30unitsaway. ArtunionR90 and independentlyshrunkphysicalunionR76 diverge at concavejoins. Stormwindv3 now defines wallClearance14 plus1,025exposed wallVertices fromtheanalyticcapsuleunion. Old-radiusinsidepoint is a safe fastpath; outsideit, exposedarc/lineprojections and junctions measure realunionclearance. All12artassets are unchanged; paintedroad56/wall76 source dimensions/gates/spawn remain. FullSpeedToWalls keepsnormalgrip/drift/boost. Existing radial/endpointstreetmodel retained, notneworientedbody/continuoussweep.

NearestDrivable nowfiltersallowed/movementbound before ranking, considers trueboundaryoffsets and vertexclearance/movement-circle intersections. This fixes both suppressedreachablelegacyprojection and near-tangentialrealwallslide. Default Circuitclassification and globalPhysics7/othertracks unchanged; no perstepUIobjects/assets/callbackchanges. Pool71/165/80. Pipeline`circuit_boundary.py` is purestandardlibrary, enumeratesexposedanalyticintersections (notimagepixels), canonicalrounding matchesruntimeLua, data vertices8decimals; generatedCapitalCities mustcome fromtheupdatedversion3pipeline.

Claude: preserve Stormwindversion3, full_speed_to_walls, wall_clearance and the boundarybuilder dependency/data when addingcities. Your activecheckout stays78d97a1; do notoverwrite this with older generatedCapitalCities/Circuit. Coordinate your nextmerge with thisfix and prior stagingbackgroundrepair/fullspeedpolicy. Existingartneednotberebuilt. SharedAPI optionalfields documented inAPI_CONTRACTS. CurrentSessionTransport stilldoesnotofferStormwind.

## Executed checks

- `python tests/test_circuit_boundary.py -q`: PASS9analytic tests.
- ActualLua5.1 `scripts/test_lua.py --runtime lua51 --tests circuit physics surface obstacles ui`: PASS52parsed/fivemodules. Final `--tests circuit`: PASS after arcfix. Exactreportedpassage, actualwall14±0.1/contact, unchangedstraightpadding, legacyboundedslide, near-tangentialslide and10tickfullspeedPhysicsdrive covered.
- `scripts/build_city_tracks.py --wc3 . --geometry-only` and`--check`: PASS; structuralvalidator98paths/24TOCs/links/ledger/whitespace PASS. Fourchanged/newPythonfiles parse. All12art+10criticalnon-Circuitmodules matchf62e708.
- Independent runtime/helper mathreviews: nofundamentalblocker; caughtandcorrectedtangentialslide beforeinstall.
- Lua5.4/fullbroad/artregen/nativeperformance/ownercornerretest: **NOT RUN**. Previouspassesnotextendedtoanewclientclaim.

## Installation / next

39source/target/manifestfiles exactcommitted81cc0ed;39priorfiles backedup/verified withPowerShell7 helper. Manifest `local-artifacts/stormwind-wall-alignment/install-backups/20261022-104405-181-2649cc42360548a2a0242fc1521ba7ea/install.json`; ignoredreceipt/diagnostics inthatartifactsroot. NoWTF/SavedVariables/otheraddon/deletion. Claude/canonicalHEADs preserved; publishedcombinedc59a607 andmainunchanged. Code/documentationcommitslocalonly.

No newruntimefiles: owner **`/reload`**, thenretrythesamePark/Magecorner andwallcontact. Nativefeel/performance remainsopen. Nextsingle taskownerretake; afterwardresume boundedlive-racecontroller/pacedremotesnapshots. Multiplayerpriority/gates androadmapacceptance unchanged.
