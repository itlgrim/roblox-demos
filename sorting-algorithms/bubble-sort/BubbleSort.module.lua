local BubbleSortDemo = {}

-- ARRAY CONSTANTS
local DICE_COUNT = 30
local DICE_HEIGHT_VARIATIONS = 20

-- DICE PROPERTIES
local DICE_BASE_SIZE = Vector3.new(4, 4, 0.4)
local DICE_COLOR_START = Color3.fromRGB(128, 128, 128)
local DICE_COLOR_SWAP = Color3.fromRGB(255, 251, 0)
local DICE_COLOR_FINISH = Color3.fromRGB(0, 255, 0)
local DICE_BRICK_COLOR_FINISH = BrickColor.new("Lime green")
local DICE_MATERIAL = "Metal"
local DICE_HEIGHT_STEP = 1.1
local DICE_DISTANCE_BETWEEN = 2
local DICE_ABOVE_SURFACE = 1.5
local DICE_COMPARE_DISTANCE = 6

-- TIMINGS
local WAIT_BEFORE_SELECT = 0.125
local MOVE_TO_COMPARE = 0.35
local WAIT_BEFORE_COMPARE_RESULT = 0.05
local WAIT_AFTER_COMPARE_RESULT = 0.35
local SWAP_DURATION = 0.35
local WAIT_AFTER_SWAP = 0.1
local MOVE_FROM_COMPARE = 0.35
local WAIT_BEFORE_DESELECT = 0.05

local TIME_OF_DAY_MOVING = 0.01


local TweenService = game:GetService("TweenService")

local Lighting = game:GetService("Lighting")

math.randomseed(os.time())

local function moveTimeOfDay()
	Lighting.ClockTime = Lighting.ClockTime + TIME_OF_DAY_MOVING
end


local function calcPositionOnSurface(position, sizeY)
	return Vector3.new(position.X, DICE_ABOVE_SURFACE + sizeY / 2, position.Z)
end

local function positionOnSurface(part)
	part.Position = calcPositionOnSurface(part.Position, part.Size.Y)
end

local function moveOverTime(part, endPosition, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(part, tweenInfo, {Position = endPosition})
	tween:Play()
end

local function rotateOverTime(part, angle, duration)
	local rotationTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local rotate = Vector3.new(0, angle, 0)
	local rotationTween = TweenService:Create(part, rotationTweenInfo, {Rotation = rotate})
	rotationTween:Play()
end

local function createComparatorUi(position)
	local size = Vector3.new(0.1, 4,  4)
	local part = Instance.new("Part")
	part.Size = size
	part.Position = position
	positionOnSurface(part)
	part.Material = DICE_MATERIAL
	part.Color = Color3.fromRGB(255,255,255)
	part.Anchored = true
	part.Transparency = 1
	part.Parent = game.Workspace

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = "Left"
	surfaceGui.Parent = part
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 10

	local textLabel = Instance.new("TextLabel")
	textLabel.Parent = surfaceGui
	textLabel.Text = ""
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.TextScaled = true
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.Arial

	surfaceGui.Adornee = part
	local comparatorUi = {
		part = part,
		surfaceGui = surfaceGui,
		textLabel = textLabel,
	}
	return comparatorUi
end

local function hideComparatorUi(comparatorUi)
	comparatorUi.textLabel.Text = ""
end

local function showComparatorUi(comparatorUi, left, right)
	if (left.Size.Y < right.size.Y) then
		comparatorUi.textLabel.Text = "<"
	elseif (left.Size.Y > right.Size.Y) then
		comparatorUi.textLabel.Text = ">"
	else
		comparatorUi.textLabel.Text = "="
	end
end

local function createDice(position, height)
	local diceSize = Vector3.new(DICE_BASE_SIZE.X, DICE_BASE_SIZE.Y + height * DICE_HEIGHT_STEP, DICE_BASE_SIZE.Z)
	local part = Instance.new("Part")
	part.Size = diceSize
	part.Position = position
	positionOnSurface(part)
	part.Material = DICE_MATERIAL
	part.Color = DICE_COLOR_START
	part.Anchored = true
	part.Parent = game.Workspace
	return part
end

local function createDiceArray(center, count, maxNumber)
	local result = {}
	local point = Vector3.new(center.X, center.Y, center.Z - (count / 2) * DICE_DISTANCE_BETWEEN)	
	for i = 1, count do
		local randomNumber = math.random(1, maxNumber)
		local dice = createDice(point, randomNumber)
		table.insert(result, dice)
		point = Vector3.new(point.X, point.Y, point.Z + DICE_DISTANCE_BETWEEN)
	end

	return result
end

local function selectForSwap(part)
	part.Color = DICE_COLOR_SWAP
end

local function deselect(part)
	part.Color = DICE_COLOR_START
end

local function setFinish(part)
	part.BrickColor = DICE_BRICK_COLOR_FINISH
	part.Color = DICE_COLOR_FINISH
end

local function swapClockwise(leftPart, rightPart, duration)
	leftPart.Orientation = Vector3.new(0, 0, 0)
	rightPart.Orientation = Vector3.new(0, 0, 0)

	local leftPos = leftPart.Position
	local rightPos = rightPart.Position
	local midZ = (leftPos.Z + rightPos.Z)/2
	local topPosition = Vector3.new(leftPos.X + DICE_COMPARE_DISTANCE/2, leftPos.Y, midZ)
	local bottomPosition = Vector3.new(rightPos.X - DICE_COMPARE_DISTANCE/2, rightPos.Y, midZ)	

	moveOverTime(leftPart, topPosition, duration/2)
	rotateOverTime(leftPart, -90, duration/2)
	moveOverTime(rightPart, bottomPosition, duration/2)
	rotateOverTime(rightPart, -90, duration/2)
	wait(duration/2)

	rightPos = calcPositionOnSurface(rightPos, leftPart.Size.Y)
	leftPos = calcPositionOnSurface(leftPos, rightPart.Size.Y)

	moveOverTime(leftPart, rightPos, duration/2)
	rotateOverTime(leftPart, -180, duration/2)
	moveOverTime(rightPart, leftPos, duration/2)
	rotateOverTime(rightPart, -180, duration/2)
	wait(duration/2)
end

local function trySwap(left, right, pivot, comparatorUi)
	
	local originLeftPos = left.Position
	local originRightPos = right.Position

	local leftComparePosition = pivot + Vector3.new(0,0,-DICE_COMPARE_DISTANCE / 2)
	local rightComparePosition = pivot + Vector3.new(0,0,DICE_COMPARE_DISTANCE / 2)

	leftComparePosition = calcPositionOnSurface(leftComparePosition, left.Size.Y)
	rightComparePosition = calcPositionOnSurface(rightComparePosition, right.Size.Y)

	moveOverTime(left, leftComparePosition, MOVE_TO_COMPARE)
	moveOverTime(right, rightComparePosition, MOVE_TO_COMPARE)
	wait(MOVE_TO_COMPARE + WAIT_BEFORE_COMPARE_RESULT)
	moveTimeOfDay()

	showComparatorUi(comparatorUi, left, right)
	wait(WAIT_AFTER_COMPARE_RESULT)

	if (left.Size.Y > right.Size.Y) then
		swapClockwise(left, right, SWAP_DURATION)
		wait(WAIT_AFTER_SWAP)
		moveTimeOfDay()

		originLeftPos = calcPositionOnSurface(originLeftPos, right.Size.Y)
		originRightPos = calcPositionOnSurface(originRightPos, left.Size.Y)

		hideComparatorUi(comparatorUi)
		moveOverTime(left, originRightPos, MOVE_FROM_COMPARE)
		moveOverTime(right, originLeftPos, MOVE_FROM_COMPARE)
		wait(MOVE_FROM_COMPARE)
		moveTimeOfDay()

		return true
	else
		hideComparatorUi(comparatorUi)
		moveOverTime(left, originLeftPos, MOVE_FROM_COMPARE)
		moveOverTime(right, originRightPos, MOVE_FROM_COMPARE)
		wait(MOVE_FROM_COMPARE)
		moveTimeOfDay()

		return false
	end
end


local function bubbleSort(array, pivot, spectatorDistanceX)
	local max = #array-1
	local swapped = false

	local comparePivot = pivot + Vector3.new(-spectatorDistanceX/2, 0, 0);
	local comparatorUi = createComparatorUi(comparePivot)

	while max >= 1 do
		for i = 1, max do
			wait(WAIT_BEFORE_SELECT)
			moveTimeOfDay()
			local left = array[i]
			selectForSwap(left)
			local right = array[i+1]
			selectForSwap(right)
			if (trySwap(left, right, comparePivot, comparatorUi)) then
				local buf = left
				array[i] = right
				array[i+1] = buf
			end
			wait(WAIT_BEFORE_DESELECT)
			moveTimeOfDay()
			deselect(left)
			deselect(right)
		end
		setFinish(array[max + 1])
		max = max - 1
	end
	setFinish(array[1])
end

function BubbleSortDemo.start(point, spectatorDistanceX) 
	print("Started Demo")

	local dices = createDiceArray(point, DICE_COUNT, DICE_HEIGHT_VARIATIONS)
	bubbleSort(dices, point, spectatorDistanceX)
end

return BubbleSortDemo
