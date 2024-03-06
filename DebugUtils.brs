#const DEVELOPED = False

'''''''''
' DebugUtils: Helper to print debug data.
'
' @param {string} fileOrClassName$
' @return {object}
'''''''''
function DebugUtils(fileOrClassName$ = "" as string) as object
	'#region *** Description
	' ==bsconfig.json==
	' files:[{
	'"src": "../extra/DebugUtils.brs",
	'"dest": "source/utils/debug/DebugUtils.brs"
	'}, {
	'"src": "../extra/DebugUtils.xml",
	'"dest": "components/DebugUtils.xml"
	'}, {
	'"src": "../extra/Options.xml",
	'"dest": "source/utils/debug/Options.xml"
	'	}]
	' ==.xml==
	' <script type="text/brightscript" uri="pkg:/source/utils/debug/DebugUtils.brs"/>
	' or in View
	' <DebugUtils id="debugUtils" fileOrClassName="ItemDetailsOverview2"/>
	'#endregion *** Description
	m._fileOrClassName$ = fileOrClassName$
	instance = {
		_fileOrClassName$: m._fileOrClassName$,
		_quote: Chr(34),
		'* Settings (Options) list
		settings: {}, ' Options which can be replaced


		'#region *** INIT
		''''''''''
		' init: Initialize Debug Util, set class or file and own delimeters if needed
		'
		' @param {object} setting: Configuration
		'
		' @return {object} Instance of this class
		''''''''''
		init: function(settings = {} as object) as object
			m.setSettings(settings)
			msg = Substitute("{1} {0} {1}", m.noticedMsg$, string(5, m.lineDelimeter$))
			m.printDebug(m._fileOrClassName$, msg)

			return m
		end function,

		postInstall: sub()
			m.options = (function() as object ' Get options from XML options file
				options = CreateObject("roXMLElement")
				file = ReadAsciiFile("pkg:/source/utils/debug/Options.xml")
				options.Parse(file)

				return options
			end function)()

			m.maxDashLineLength% = (function(value as string) as integer
				return StrToI(value)
			end function)(m.options?.maxDashLineLength?.GetText()) ' Depends on a screen wide

			m.inOneLinePrintable = (function(value as string) as boolean
				return LCase(value) = "true"
			end function)(m.options.inOneLinePrintable.GetText()) ' If True - print as JSON string, else, row-by-row

			m.lineDelimeter$ = m.options.lineDelimeter.GetText() ' Separate symbol between messages

			m.enabled = (function(value as string) as boolean
				return LCase(value) = "true"
			end function)(m.options.enabled.GetText()) ' Is current instance enabled and prints debug info

			m.typePrintOptions = (function(value as object) as object
				if value = invalid then return ["<<", ">>"]
				return [value.tag1, value.tag2]
			end function)(m.options?.typePrintable?.GetAttributes()) ' Symbols around of a value type

			m.typePrintable = (function(value as string) as boolean
				return LCase(value) = "true"
			end function)(m.options.typePrintable.GetText()) ' Do need to print type of a variable (simple types only)

			m.infoSymbol$ = m.options.infoSymbol.getText()

			m.printListIndex = (function(value as string) as boolean
				return LCase(value) = "true"
			end function)(m.options.printListIndex.GetText()) ' Print index before each list's element

			m.noticedMsg$ = m.options.noticedMsg.GetText()
		end sub
		'#endregion *** INIT


		'#region *** PRINT_DEBUG AND PRINT
		''''''''''
		' printDebug: Print debug information into debug console
		'
		' @param {string} method
		' @param {dynamic} msg: What to print
		''''''''''
		printDebug: sub(method as string, msg = invalid as dynamic)
			if not m.enabled then return
			inOneLinePrintable = m.inOneLinePrintable
			if(m.inOneLinePrintable) then m.inOneLinePrintable = False
			message = m._compoundMessage(method, msg)
			messageLength = Len(message)
			m._dashLine(messageLength): print message: m._dashLine(messageLength) 'bs:disable-line
			'* Call cleaner
			message = invalid 'bs:disable-line
			m.inOneLinePrintable = inOneLinePrintable
		end sub,


		''''''''''
		' print: Alias printDebug
		'
		' @param {string} method
		' @param {dynamic} msg: What to print
		''''''''''
		print: sub(method as string, msg = invalid as dynamic)
			if not m.enabled then return
			message = m._compoundMessage(method, msg)
			messageLength = Len(message)
			m._dashLine(messageLength): print message: m._dashLine(messageLength) 'bs:disable-line
			'* Call cleaner
			message = invalid 'bs:disable-line
		end sub,
		'#endregion *** PRINT_DEBUG AND PRINT


		'#region *** KEY_VALUE
		''''''''''
		' printKeyValue: Prints obj keys or obj.key : value
		' obj: object
		' props.name: displaying object name
		' props.keys: ["a", "b.c"]
		'
		' @param {string} method$: Method Name
		' @param {object} obj: Map object
		' @param {object} props: Object's properties, such as keys as Array, name as name of printable obj
		''''''''''
		printKeyValue: sub(method$ as string, obj as object, props = {} as object)
			m.printDebug(method$, m.getKeyValue(obj, props))
		end sub,


		'''''''''
		' getKeyValue: Get obj keys or obj.key : value
		' obj: object
		' props.name: displaying object name
		' props.keys: ["a", "b.c"]
		'
		' @param {object} obj: Map object
		' @param {object} props: Object's properties, such as keys as Array, name as name of printable obj
		getKeyValue: function(obj as object, props = {} as object) as object
			name = "objName"
			if props.DoesExist("name") then name = props.name
			msg = {}
			valueType = Type(obj)
			isObj = (valueType = "roAssociativeArray" or valueType = "roSGNode")
			if (not isObj) then msg.error = name + ": This is not an object": return msg

			keys = []
			if props.DoesExist("keys") then keys = props.keys

			if (keys.ifArray.count() = 0)
				msg.oKeys = obj.ifAssociativeArray.keys?()
			else
				filteredObj = {}
				for each key in keys
					if (key.inStr(".") > -1)
						splitKeys = key.split(".")
						currentSplitObject = obj[splitKeys[0]]
						for i = 1 to splitKeys.count() - 1
							if (Type(currentSplitObject) = "roAssociativeArray")
								currentSplitObject = currentSplitObject[splitKeys[i]]
							end if
						end for
						filteredObj[key] = currentSplitObject
					else
						filteredObj[key] = obj[key]
					end if
				end for
				msg[name] = filteredObj
			end if
			'* Call cleaner
			filteredObj = invalid 'bs:disable-line

			return msg
		end function,

		'#endregion *** KEY_VALUE


		'#region *** SET_SETTINGS
		''''''''''
		' setSettings: apply settings
		'
		' @param {object} settings: Class properties
		''''''''''
		setSettings: sub(settings as object)
			if (not settings.isEmpty())
				for each setting in settings.Items()
					m[setting.key] = setting.value
				end for
			end if
		end sub,
		'#endregion *** SET_SETTINGS


		'#region *** STOP
		''''''''''
		' stop: stop running an application
		'
		' @param {string}? Method where it placed
		' @param {string|dynamic}? Some data
		''''''''''
		stop: sub(method$ = "Undefined" as string, msg = "STOP" as dynamic)
			m.printDebug(method$, msg)
			stop 'bs:disable-line
		end sub,
		'#endregion *** STOP


		''''''''''
		' infoPane: Add InfoPane node to screen
		'
		' @param {string} Method where it placed
		' @param {object} props settings
		' @see https://developer.roku.com/en-ca/docs/references/scenegraph/label-nodes/info-pane.md
		''''''''''
		infoPane: sub(method$ as string, props as object)
			parent = props?.parent
			if parent = invalid then m.printDebug(method$, "TOP isn't defined"): return

			infoPaneNode = CreateObject("roSGNode", "infoPane")
			settings = ["infoText", "width", "height", "bulletText", "translation", "textColor"]
			fields = {"infoText2": m._compoundTitle(method$), "infoText2BottomAlign": True, "infoText2Color": "0xFF0000"}
			for each setting in settings
				value = props.ifAssociativeArray.LookupCI(setting)
				if (value <> invalid)
					if (setting = "infoText") then value = m.convertToStr(value)
					fields[setting] = value
				end if
			end for
			infoPaneNode.setFields(fields)
			parent.appendChild(infoPaneNode)
		end sub,


		''''''''''
		' checkValueType: Check current type with expected: strings, numerics, booleans..Abs.
		'
		' @param {string} valueType Type(value)
		' @param {string|roArray} expectedType strings, ["strings","numerics"]
		' @return {boolean}
		checkValueType: function(valueType as string, expected as dynamic) as boolean
			expectedType = Type(expected)
			if (expectedType = "String") then return m._checkValueType(valueType, expected)
			if (expectedType = "roArray")
				for each item in expected
					matched = m._checkValueType(valueType, item)
					if matched then return True
				end for
			end if

			return False
		end function,


		''''''''''
		' convertToStr: simple string converter
		'
		' @param {dynamic} value: Convertable value
		' @return {string}
		''''''''''
		convertToStr: function(value as dynamic) as string
			try
				valueType = Type(value)

				if (m.checkValueType(valueType, ["numerics", "booleans"])) then return m._addTypeBeforeValue(valueType, value.toStr())

				if m.checkValueType(valueType, "strings") then return m._addTypeBeforeValue(valueType, Substitute("{1}{0}{1}", value, m._quote))

				if (valueType = "roAssociativeArray" or valueType = "roSGNode") then return m._addTypeBeforeValue(valueType, m._convertAssocArrayToStr(value))

				if (valueType = "roArray" or valueType = "roList") then return m._addTypeBeforeValue(valueType, m._convertListToStr(value))
				if (valueType = "<uninitialized>") then return Substitute("{1}{0}{1}", valueType, m._quote)

				if (value = invalid) then return Substitute("{0}invalid{0}", m._quote)

				if (valueType = "roRegistry") then return m._addTypeBeforeValue(valueType, m._convertListToStr(value.GetSectionList()))
				if (valueType = "roRegistrySection") then return m._addTypeBeforeValue(valueType, m._convertListToStr(value.GetKeyList()))

				return Substitute("{1}{0}{1}", valueType, m._quote)
			catch err

				return Substitute("error: {0}", err.message)
			end try
		end function,


		''''''''''
		' assert: Assertion check. If falls throw exception
		'
		' @param {boolean} value: Assertion condition
		' @param {string|object}: Printable data, message
		''''''''''
		assert: sub(value as boolean, vargs = "" as dynamic)
			if not value then throw {"message": m.convertToStr(vargs)}
		end sub

		' PRIVATE

		'#region *** PRIVATE


		'#region *** private COMPOUND_MESSAGE
		''''''''''
		' _compoundMessage: Build printable message
		'
		' @param {string} method$: Where is places print
		' @param {dynamic} msg: What to print
		' @return {string}
		''''''''''
		_compoundMessage: function(method$ as string, msg as dynamic) as string
			debugText$ = (function(lineDelimeter$ as string) as string
				timeStamp = function() as string
					addZeroPrefix = function(value as integer) as string
						if (value < 10) then return Substitute("0{0}", value.toStr())
						return value.toStr()
					end function
					dateTime = CreateObject("roDateTime")
					return Substitute("{0}:{1}:{2}.{3}", addZeroPrefix(dateTime.GetHours()), addZeroPrefix(dateTime.GetMinutes()), addZeroPrefix(dateTime.GetSeconds()), dateTime.GetMilliseconds().toStr())
				end function
				debugText$ = Substitute("{0}{1}DebugUtils", timeStamp(), lineDelimeter$)
				return debugText$
			end function)(m.lineDelimeter$)
			fullMessage = m._compoundTitle(method$, debugText$)
			message = ""
			if (msg <> invalid) then message = m.convertToStr(msg)

			if (Len(message) > 0) then fullMessage += Substitute("{1}{2}{0}", message, Chr(10), m.infoSymbol$)
			'* Call cleaner
			message = invalid 'bs:disable-line

			return fullMessage
		end function,


		_compoundTitle: function(method$ as string, debugText$ = "" as string) as string
			if (m._fileOrClassName$ = "" or m._fileOrClassName$ = method$) then return Substitute("{1}{2}{1} {0}()", method$, m.lineDelimeter$, debugText$)
			return Substitute("{2}{3}{2} {0}.{1}()", m._fileOrClassName$, method$, m.lineDelimeter$, debugText$)
		end function,

		'#endregion *** private COMPOUND_MESSAGE

		'#region *** private DASH_LINE
		''''''''''
		' _dashLine: print dash line with message length
		'
		' @param {integer} length%: length of string
		''''''''''
		_dashLine: sub(length% as integer)
			str = string(length%, m.lineDelimeter$)
			print Left(str, m.maxDashLineLength%) 'bs:disable-line
		end sub,
		'#endregion *** private DASH_LINE


		'#region *** private CONVERT_TO_STRING

		''''''''''
		' _convertAssocArrayToStr: simple associative array to string converter
		'
		' @param {object}: AA 2 string
		' @return {string}
		''''''''''
		_convertAssocArrayToStr: function(obj as object) as string
			message = ""
			nodeKeys = obj.Keys()
			eonL = (function(inOneLinePrintable as boolean) as string
				comma = ", "
				if inOneLinePrintable then return comma
				return comma + Chr(10)
			end function)(m.inOneLinePrintable)

			nodeKeysCount = nodeKeys.ifArray.Count()
			if (nodeKeysCount > 0)
				lastKey = nodeKeys[nodeKeysCount - 1]
				for each nodeKey in nodeKeys
					convertedValue = m.convertToStr(obj[nodeKey])
					initSpace = (function(inOneLinePrintable as boolean) as string
						if (inOneLinePrintable) then return ""
						return " "
					end function)(m.inOneLinePrintable)

					message += Substitute("{3}{2}{0}{2}:{1}", nodeKey, convertedValue, m._quote, initSpace)
					if (nodeKey <> lastKey) then message += eonL
				end for
			end if

			if (m.inOneLinePrintable or len(message) = 0) then return Substitute("{{0}}", message)
			return Substitute("{{1}{0}{1}}", message, Chr(10))
		end function,


		''''''''''
		' _convertListToStr: roList, roArray string converter
		'
		' @param {object} obj: Array or List
		' @return {string}
		''''''''''
		_convertListToStr: function(obj as object) as string
			message = ""
			countOff = obj.Count()
			if (countOff > 0)
				lastIndex = countOff - 1
				for i = 0 to lastIndex
					if (i > 0 and i <= lastIndex) then message += ", "
					if not m.inOneLinePrintable then message += Chr(10)
					if m.printListIndex and not m.inOneLinePrintable then message += Substitute("[{0}]", i.toStr())
					message += m.convertToStr(obj[i])
				end for
			end if

			return Substitute("[{0}]", message)
		end function,
		'#endregion *** private CONVERT_TO_STRING


		'#region *** private GET_QUOTES
		''''''''''
		' _getDblQuotes: make quotes
		'
		' @return {string}
		''''''''''
		_getDblQuotes: function() as string
			return string(2, m.quote)
		end function
		'#endregion *** private GET_QUOTES


		''''''''''
		' _checkValueType: Check current type with expected: strings, numerics, booleans..Abs.
		'
		' @param {string} valueType Type(value)
		' @param {string} expectedType strings..
		' @return {boolean}
		_checkValueType: function(valueType as string, expectedType as string) as boolean
			types = CreateObject("roXMLList")
			optTypes = m.options?.types
			if (optTypes?.strings <> invalid and expectedType = "strings") then types = optTypes.strings
			if (optTypes?.numerics <> invalid and expectedType = "numerics") then types = optTypes.numerics
			if (optTypes?.booleans <> invalid and expectedType = "booleans") then types = optTypes.booleans
			if (optTypes?.funcions <> invalid and expectedType = "functions") then types = optTypes.functions
			for each item in types
				REM roXMLElement getAttributes()
				if (valueType = item@type) then return True
			end for

			return False
		end function,


		''''''''''
		' _addTypeBeforeValue: Check and add a type of value before it, rounded typePrintOptions array values
		'
		' @param {string} typeOf: Value's type
		' @param {string} inputData: Value's data
		' @return {string}
		''''''''''
		_addTypeBeforeValue: function(typeOf as string, inputData as string) as string
			if m.typePrintable
				return Substitute("{1}{0}{2}{3}", typeOf, m.typePrintOptions[0], m.typePrintOptions[1], inputData)
			end if
			return inputData
		end function,

		'#endregion *** PRIVATE
	}
	instance.postInstall()

	m._debugUtilsSingelton = instance

	return m._debugUtilsSingelton
end function


' #region *** roSGNode API

sub onFileNameSet(event as object)
	m.debUt = DebugUtils().init(event.getData())
end sub

sub onSettingsSet(event as object)
	m.debUt.setSettings(event.getData())
end sub

sub printDebug(method$ as string, msg = invalid as dynamic)
	m.debUt.printDebug(method$, msg)
end sub

sub printD(method$ as string, msg = invalid as dynamic)
	m.debUt.print(method$, msg)
end sub

sub printKeyValue(method$ as string, obj as object, props = {} as object)
	m.debUt.printKeyValue(method$, obj, props)
end sub

function getKeyValue(obj as object, props = {} as object) as object
	return m.debUt.getKeyValue(obj, props)
end function

sub stopD(method$ as string, props as object)
	m.debUt.stop(method$, props)
end sub

sub infoPane(method$ as string, props as object)
	m.debUt.infoPane(method$, props)
end sub

'#endregion *** roSGNode API
