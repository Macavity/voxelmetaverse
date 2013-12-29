# vim: set shiftwidth=2 tabstop=2 softtabstop=2 expandtab:

ever = require 'ever'
datgui = require 'dat-gui'

ItemPile = require 'itempile'
Inventory = require 'inventory'
InventoryWindow = require 'inventory-window'
{Recipe, AmorphousRecipe, PositionalRecipe, CraftingThesaurus, RecipeLocator} = require 'craftingrecipes'

createGame = require 'voxel-engine'
createPlugins = require 'voxel-plugins'

# plugins (loaded by voxel-plugins; listed here for browserify)
require 'voxel-registry'
require 'voxel-carry'
require 'voxel-workbench'
require 'voxel-chest'
require 'voxel-inventory-hotbar'
require 'voxel-inventory-dialog'
require 'voxel-oculus'
require 'voxel-highlight'
require 'voxel-player'
require 'voxel-fly'
require 'voxel-walk'
require 'voxel-mine'
require 'voxel-harvest'
require 'voxel-use'
require 'voxel-reach'
require 'voxel-land'
require 'voxel-blockdata'

require 'voxel-debug'
require 'voxel-plugins-ui'
require 'kb-bindings-ui'

module.exports = () ->
  console.log 'voxpopuli starting'

  if window.performance && window.performance.timing
    loadingTime = Date.now() - window.performance.timing.navigationStart
    console.log "User-perceived page loading time: #{loadingTime / 1000}s"

  # setup the game 
  console.log 'creating game'
  game = createGame {
    lightsDisabled: true
    arrayType: Uint16Array
    #generate: voxel.generator['Valley']
    #generateVoxelChunk: terrain {chunkSize: 32, chunkDistance: 2, seed: 42}
    useAtlas: false
    generateChunks: false
    chunkDistance: 2
    materials: []  # added dynamically later
    texturePath: 'AssetPacks/ProgrammerArt/textures/blocks/' # subproject with textures
    worldOrigin: [0, 0, 0]
    controls:
      discreteFire: false
      fireRate: 100 # ms between firing
      jumpTimer: 25
    keybindings:
      # voxel-engine defaults
      'W': 'forward'
      'A': 'left'
      'S': 'backward'
      'D': 'right'
      '<up>': 'forward'
      '<left>': 'left'
      '<down>': 'backward'
      '<right>': 'right'
      '<mouse 1>': 'fire'
      '<mouse 3>': 'firealt'
      '<space>': 'jump'
      '<shift>': 'crouch'
      '<control>': 'alt'
      '<tab>': 'sprint'

      # our extras
      'R': 'pov'
      'T': 'vr'
      'O': 'home'
      'E': 'inventory'
      'C': 'gamemode'
    }

  # add lighting - based on voxel-engine addLights()
  ambientLight = new game.THREE.AmbientLight(0x888888)
  game.scene.add(ambientLight)
  directionalLight = new game.THREE.DirectionalLight(0xffffff, 1)
  directionalLight.position.set(1, 1, 0.5).normalize()
  game.scene.add(directionalLight)


  console.log 'initializing plugins'
  plugins = createPlugins game, {require: require}

  configuration = {
    'voxel-registry': {}
    'craftingrecipes': {}
    'voxel-carry': {inventoryWidth:10, inventoryRows:5}
    'voxel-blockdata': {}
    'voxel-chest': {}
    'voxel-workbench': {}
    'voxel-land': {populateTrees: true}
    # note: onDemand so doesn't automatically enable
    'voxel-oculus': { distortion: 0.2, separation: 0.5, onDemand: true } # TODO: switch to voxel-oculus-vr? https://github.com/vladikoff/voxel-oculus-vr?source=c - closer matches threejs example
    'voxel-player': {image: 'player.png'}
    'voxel-fly': {flySpeed: 0.8, onDemand: true}
    'voxel-walk': {}
    'voxel-inventory-hotbar': {inventorySize:10}
    'voxel-inventory-dialog': {}
    'voxel-reach': { reachDistance: 8 }
    # left-click hold to mine
    'voxel-mine': {
      instaMine: false
      progressTexturesPrefix: 'destroy_stage_'
      progressTexturesCount: 9
    }
    # right-click to place block (etc.)
    'voxel-use': {}
    # handles 'break' event from voxel-mine (left-click hold breaks blocks), collects block and adds to inventory
    'voxel-harvest': {}
    # highlight blocks when you look at them
    'voxel-highlight': {
      color:  0xff0000
      distance: 8,
      adjacentActive: () -> false   # don't hold <Ctrl> for block placement (right-click instead, 'reach' plugin) # TODO: not serializable, problem?
    }
    # the GUI window (built-in toggle with 'H')
    'voxel-debug': {}
    'voxel-plugins-ui': {}
    'kb-bindings-ui': {}
  }

  for name, opts of configuration
    plugins.add name, opts

  plugins.loadAll()
  ## plugins are loaded from here on out ##


  if window.location.href.indexOf('rift') != -1 ||  window.location.hash.indexOf('rift') != -1
    # Oculus Rift support
    plugins.enable 'oculus'
    document.getElementById('logo').style.visibility = 'hidden'

  # the game view element itself
  container = document.body
  window.game = window.g = game # for debugging
  game.appendTo container
  return game if game.notCapable()


  # pickaxe TODO: move to new module?
  registry = plugins.get('voxel-registry')
  registry.registerItem 'pickaxeWood', {itemTexture: '../items/wood_pickaxe', speed: 2.0} # TODO: fix path
  registry.registerItem 'pickaxeDiamond', {itemTexture: '../items/diamond_pickaxe', speed: 10.0}
  registry.registerItem 'stick', {itemTexture: '../items/stick'}

  # recipes
  recipes = plugins.get('craftingrecipes')
  recipes.thesaurus.registerName 'wood.log', new ItemPile('logOak')
  recipes.thesaurus.registerName 'wood.log', new ItemPile('logBirch')
  recipes.thesaurus.registerName 'wood.plank', new ItemPile('plankOak')
  recipes.thesaurus.registerName 'tree.leaves', new ItemPile('leavesOak')

  recipes.register new AmorphousRecipe(['wood.log'], new ItemPile('plankOak', 2))
  recipes.register new AmorphousRecipe(['wood.plank', 'wood.plank'], new ItemPile('stick', 4))

  recipes.register new PositionalRecipe([
    ['wood.plank', 'wood.plank', 'wood.plank'],
    [undefined, 'stick', undefined],
    [undefined, 'stick', undefined]], new ItemPile('pickaxeWood', 1))

  # temporary recipe
  recipes.register new PositionalRecipe([
    ['tree.leaves', 'tree.leaves', 'tree.leaves'],
    [undefined, 'stick', undefined],
    [undefined, 'stick', undefined]], new ItemPile('pickaxeDiamond', 1))


  avatar = plugins.get('voxel-player')
  avatar.pov('first');
  avatar.possess()
  home(avatar)

  # load textures after all plugins loaded (since they may add their own)
  registry = plugins.get('voxel-registry')
  game.materials.load registry.getBlockPropsAll 'texture'
  global.InventoryWindow_defaultGetTexture = (itemPile) => registry.getItemPileTexture(itemPile) # TODO: cleanup

  #playerInventory = game.plugins.get('voxel-carry').inventory
  #playerInventory.give new ItemPile('pickaxeDiamond', 1)
  #playerInventory.give new ItemPile('stick', 32)
  #playerInventory.give new ItemPile('logOak', 10)
  #playerInventory.give new ItemPile('plankOak', 10)
  #playerInventory.give new ItemPile('logBirch', 5)
  #playerInventory.give new ItemPile('workbench', 1)
  #playerInventory.give new ItemPile('chest', 5)


  game.mode = 'survival'

  # one of everything, please..
  creativeInventoryArray = []
  for props in registry.blockProps
    creativeInventoryArray.push(new ItemPile(props.name, Infinity)) if props.name?

  survivalInventoryArray = []

  game.buttons.down.on 'pov', () -> avatar.toggle() # TODO: disable/re-enable voxel-walk in 1st/3rd person?
  game.buttons.down.on 'vr', () -> plugins.toggle 'voxel-oculus'
  game.buttons.down.on 'home', () -> home(avatar)
  game.buttons.down.on 'inventory', () -> plugins.get('voxel-inventory-dialog')?.toggle()
  inventoryHotbar = plugins.get('voxel-inventory-hotbar')
  game.buttons.down.on 'gamemode', () ->
    # TODO: add gamemode event? for plugins to handle instead of us
    if game.mode == 'survival'
      game.mode = 'creative'
      plugins.enable 'voxel-fly'
      plugins.get('voxel-mine')?.instaMine = true
      survivalInventoryArray = inventoryHotbar.inventory.array
      inventoryHotbar.inventory.array = creativeInventoryArray
      inventoryHotbar.refresh()
      console.log 'creative mode'
    else
      game.mode = 'survival'
      plugins.disable 'voxel-fly'
      plugins.get('voxel-mine')?.instaMine = false
      inventoryHotbar.inventory.array = survivalInventoryArray
      inventoryHotbar.refresh()
      console.log 'survival mode'


  # show origin 
  plugins.get('voxel-debug').axis [0, 0, 0], 10

  return game

home = (avatar) ->
  avatar.yaw.position.set 2, 14, 4


