/*
 * @flow
 */

import type {Suite} from "flow-dev-tools/src/test/Suite";
const {suite, test} = require('flow-dev-tools/src/test/Tester');

module.exports = (suite(({addFile, removeFile, flowCmd}) => [
  test('node - Adding a package.json should kill the server', [
    addFile('start.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('node_flowconfig').noAutoRestart(),
  test('haste - Adding a package.json should kill the server', [
    addFile('start.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('haste_flowconfig').noAutoRestart(),

  test('node - Removing a package.json should kill the server', [
    addFile('start.json', 'package.json'),
    removeFile('package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('node_flowconfig').noAutoRestart(),
  test('haste - Removing a package.json should kill the server', [
    addFile('start.json', 'package.json'),
    removeFile('package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('haste_flowconfig').noAutoRestart(),

  test('node - Changing the name field should kill the server', [
    addFile('start.json', 'package.json'),
    addFile('nameChange.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('node_flowconfig').noAutoRestart(),
  test('haste - Changing the name field should kill the server', [
    addFile('start.json', 'package.json'),
    addFile('nameChange.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('haste_flowconfig').noAutoRestart(),

  test('node - Changing the main field should kill the server', [
    addFile('start.json', 'package.json'),
    addFile('mainChange.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('node_flowconfig').noAutoRestart(),
  test('haste - Changing the main field should kill the server', [
    addFile('start.json', 'package.json'),
    addFile('mainChange.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('haste_flowconfig').noAutoRestart(),

  test('node - Changing an irrelevant field should NOT kill the server', [
    addFile('start.json', 'package.json'),
    addFile('irrelevantChange.json', 'package.json')
      .startFlowServer() // makes this step start Flow before irrelevantChange is added
      .waitUntilServerStatus(2000, 'stopped') // only 2s not 10s so as not to waste time
      .verifyServerStatus('running'),
  ]).flowConfig('node_flowconfig'),
  test('haste - Changing an irrelevant field should NOT kill the server', [
    addFile('start.json', 'package.json'),
    addFile('irrelevantChange.json', 'package.json')
      .startFlowServer() // makes this step start Flow before irrelevantChange is added
      .waitUntilServerStatus(2000, 'stopped') // only 2s not 10s so as not to waste time
      .verifyServerStatus('running'),
  ]).flowConfig('haste_flowconfig'),

  test('node - Making package invalid should kill the server', [
    addFile('start.json', 'package.json'),
    addFile('invalidPackage.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('node_flowconfig').noAutoRestart(),
  test('haste - Making package invalid should kill the server', [
    addFile('start.json', 'package.json'),
    addFile('invalidPackage.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(10000, 'stopped')
      .verifyServerStatus('stopped'),
  ]).flowConfig('haste_flowconfig').noAutoRestart(),

  test('node - Changes to an invalid package should NOT kill the server', [
    addFile('invalidPackage.json', 'package.json'),
    addFile('invalidPackage2.json', 'package.json')
      .startFlowServer() // makes this step start Flow before invalidPackage2 is added
      .waitUntilServerStatus(2000, 'stopped') // only 2s not 10s so as not to waste time
      .verifyServerStatus('running'),
  ]).flowConfig('node_flowconfig').noAutoRestart(),
  test('haste - Changes to an invalid package should NOT kill the server', [
    addFile('invalidPackage.json', 'package.json')
      .startFlowServer() // makes this step start Flow before invalidPackage2 is added
      .waitUntilServerStatus(2000, 'stopped') // only 2s not 10s so as not to waste time
      .verifyServerStatus('running'),
    addFile('invalidPackage2.json', 'package.json')
      .verifyServerStatus('running'),
  ]).flowConfig('haste_flowconfig').noAutoRestart(),

 test('node - When using main_fields, a change which resolves to '+
    'the same main file should NOT kill the server', [
    addFile('start.json', 'package.json'),
    addFile('irrelevantChangeMainField.json', 'package.json')
      .startFlowServer()
      .waitUntilServerStatus(2000, 'stopped') // only 2s not 10s so as not to waste time
      .verifyServerStatus('running')
  ]).flowConfig('node_flowconfig_with_main_field').noAutoRestart(),
]): Suite);
