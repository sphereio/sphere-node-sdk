{InventorySync} = require '../../lib/main'

describe 'InventorySync', ->

  beforeEach ->
    @sync = new InventorySync

  afterEach ->
    @sync = null

  describe ':: config', ->

    it 'should build white/black-listed actions update', ->
      opts = [
        {type: 'quantity', group: 'white'}
        {type: 'expectedDelivery', group: 'black'}
        {type: 'restockableInDays', group: 'black'}
      ]
      newInventory =
        id: '123'
        quantityOnStock: 2
        version: 1
      oldInventory =
        id: '123'
        quantityOnStock: 10
        version: 1
      spyOn(@sync._utils, 'actionsMapExpectedDelivery').andReturn [{action: 'setExpectedDelivery', expectedDelivery: "2001-09-11T14:00:00.000Z"}]
      spyOn(@sync._utils, 'actionsMapRestockableInDays').andReturn [{action: 'setRestockableInDays', restockableInDays: 7}]
      update = @sync.config(opts).buildActions(newInventory, oldInventory).getUpdatePayload()
      expected_update =
        actions: [
          { action: 'changeQuantity', quantity: 2 }
        ]
        version: oldInventory.version
      expect(update).toEqual expected_update

  describe ':: buildActions', ->

    it 'no differences', ->
      ie =
        id: 'abc'
        sku: '123'
        quantityOnStock: 7
      update = @sync.buildActions(ie, ie).getUpdatePayload()
      expect(update).toBeUndefined()
      updateId = @sync.buildActions(ie, ie).getUpdateId()
      expect(updateId).toBe 'abc'

    it 'more quantity', ->
      ieNew =
        sku: '123'
        quantityOnStock: 77
      ieOld =
        sku: '123'
        quantityOnStock: 9
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'changeQuantity'
      expect(update.actions[0].quantity).toBe 77

    it 'less quantity', ->
      ieNew =
        sku: '123'
        quantityOnStock: 7
      ieOld =
        sku: '123'
        quantityOnStock: 9
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'changeQuantity'
      expect(update.actions[0].quantity).toBe 7

    it 'should add expectedDelivery', ->
      ieNew =
        sku: 'xyz'
        quantityOnStock: 9
        expectedDelivery: '2014-01-01T01:02:03'
      ieOld =
        sku: 'xyz'
        quantityOnStock: 9
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setExpectedDelivery'
      expect(update.actions[0].expectedDelivery).toBe '2014-01-01T01:02:03'

    it 'should update expectedDelivery', ->
      ieNew =
        sku: 'abc'
        quantityOnStock: 0
        expectedDelivery: '2000'
      ieOld =
        sku: 'abc'
        quantityOnStock: 0
        expectedDelivery: '1999'
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setExpectedDelivery'
      expect(update.actions[0].expectedDelivery).toBe '2000'

    it 'should remove expectedDelivery', ->
      ieNew =
        sku: 'abc'
        quantityOnStock: 0
      ieOld =
        sku: 'abc'
        quantityOnStock: 0
        expectedDelivery: '1999'
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setExpectedDelivery'
      expect(update.actions[0].expectedDelivery).toBeUndefined()

    it 'should add restockableInDays', ->
      ieNew =
        sku: 'ijk'
        quantityOnStock: 5
        restockableInDays: 7
        version: 1
      ieOld =
        sku: 'ijk'
        quantityOnStock: 5
        version: 1
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setRestockableInDays'
      expect(update.actions[0].restockableInDays).toBe 7

    it 'should update restockableInDays', ->
      ieNew =
        sku: 'oik'
        quantityOnStock: 0
        restockableInDays: 3
        version: 1
      ieOld =
        sku: 'oik'
        quantityOnStock: 0
        restockableInDays: 7
        version: 1
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setRestockableInDays'
      expect(update.actions[0].restockableInDays).toBe 3

    it 'should remove restockableInDays', ->
      ieNew =
        sku: 'oik'
        quantityOnStock: 0
        version: 1
      ieOld =
        sku: 'oik'
        quantityOnStock: 0
        version: 1
        restockableInDays: 10
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setRestockableInDays'
      expect(update.actions[0].restockableInDays).toBeUndefined()

    it 'no differences in restockableInDays', ->
      ie =
        id: '234'
        sku: 'bcd'
        quantityOnStock: 3
        restockableInDays: 8
      update = @sync.buildActions(ie, ie).getUpdatePayload()
      expect(update).toBeUndefined()
      updateId = @sync.buildActions(ie, ie).getUpdateId()
      expect(updateId).toBe '234'

    it 'more differences in restockableInDays', ->
      ieNew =
        sku: 'ijk'
        quantityOnStock: 3
        restockableInDays: 20
      ieOld =
        sku: 'ijk'
        quantityOnStock: 3
        restockableInDays: 4
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setRestockableInDays'
      expect(update.actions[0].restockableInDays).toBe 20

    it 'less differences in restockableInDays', ->
      ieNew =
        sku: 'oik'
        quantityOnStock: 3
        restockableInDays: 5
      ieOld =
        sku: 'oik'
        quantityOnStock: 3
        restockableInDays: 15
      update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
      expect(update).toBeDefined()
      expect(update.actions[0].action).toBe 'setRestockableInDays'
      expect(update.actions[0].restockableInDays).toBe 5

    describe 'actionsMapCustom', ->
      ieNew =
        sku: 'abc'
        custom: {
          type: {
            typeId: 'type',
            id: '123'
          },
          fields: {
            nac: 'ho',
            pie: {
              'nl': 'taart'
            }
          }
        }

      it 'should set empty new custom type and fields', ->
        ieOld =
          sku: 'abc'
          custom: {}

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomType'
        expect(update.actions[0].type).toEqual { typeId: 'type', id: '123' }
        expect(update.actions[0].fields).toEqual { nac: 'ho', pie: {nl:'taart'} }

      it 'should set completely new custom type and fields', ->
        ieOld =
          sku: 'abc'

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomType'
        expect(update.actions[0].type).toEqual { typeId: 'type', id: '123' }
        expect(update.actions[0].fields).toEqual { nac: 'ho', pie: {nl: 'taart'} }

      it 'should update custom type', ->
        ieOld =
          sku: 'abc'
          custom: {
            type: {
              typeId: 'type',
              id: '000'
            }
          }

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomType'
        expect(update.actions[0].type).toEqual { typeId: 'type', id: '123' }

      it 'should update custom fields', ->
        ieOld =
          sku: 'abc'
          custom: {
            type: {
              typeId: 'type',
              id: '123'
            },
            fields: {
              nac: 'choo'
            }
          }

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomField'
        expect(update.actions[0].name).toBe 'nac'
        expect(update.actions[0].value).toBe 'ho'

      it 'should update localized custom fields', ->
        ieOld =
          sku: 'abc'
          custom: {
            type: {
              typeId: 'type',
              id: '123'
            },
            fields: {
              nac: 'ho',
              pie: {
                'nl': 'echt niet'
              }
            }
          }

        update = @sync.buildActions(ieNew, ieOld).getUpdatePayload()
        expect(update.actions[0].action).toBe 'setCustomField'
        expect(update.actions[0].name).toBe 'pie'
        expect(update.actions[0].value).toEqual {'nl': 'taart'}
