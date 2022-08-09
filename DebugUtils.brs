' ==bsconfig.json==
' files:[{
'	"src": "../extra/debug/DebugUtils.brs",
'"dest": "source/utils/debug/DebugUtils.brs"
'	}]
' ==.xml==
' <script type="text/brightscript" uri="pkg:/source/utils/debug/DebugUtils.brs"/>

'''''''''
' DebugUtils: Helper to print debug data.
'
' @return {object}
'''''''''
function DebugUtils() as object
	instance = {
		fileOrClassName$: "",
		quote: Chr(34),
		noticedMsg: "Don't forget remove Debug Utility"
		' Settings (Options) list
		settings: {}, ' Options which can be replaced
		maxDashLineLength: 100, ' Depends on a screen wide
		inOneLinePrintable: true, ' If true - print as JSON string, else, row-by-row
		lineDelimeter$: "-", ' Separate symbol between messages
		enabled: true, ' Is current instance enabled and prints debug info
		typePrintOptions: ["<<", ">>"] ' Symbols around of a value type
		typePrintable: false, ' Do need to print type of a variable (simple types only)

		''''''''''
		' init: Initialize Debug Util, set class or file and own delimeters if needed
		'
		' @param {string} fileOrClassName$
		' @param {object} setting: Configuration
		'
		' @return {object} Instance of this class
		''''''''''
		init: function(fileOrClassName$ as string, settings = {} as object) as object
			m.fileOrClassName$ = fileOrClassName$
			m.setSettings(settings)
			msg = Substitute("{1} {0} {1}", m.noticedMsg, string(5, m.lineDelimeter$))
			m.printDebug(m.fileOrClassName$, msg)

			return m
		end function,

		''''''''''
		' printDebug: Print debug information into debug console
		'
		' @param {string} method
		' @param {dynamic} msg: What to print
		''''''''''
		printDebug: sub(method as string, msg = invalid as dynamic)
			message = ""
			if m.enabled then message = m._compoundMessage(method, msg)
			messageLength = Len(message)
			m._dashLine(messageLength): print message: m._dashLine(messageLength)
			message = invalid
		end sub,

		''''''''''
		' getKeysValues: Prints obj keys or obj.key : value
		' obj: object
		' name: displaying object name
		' keys: ["a", "b.c"]
		' }
		'
		' @param {string} method: Where is places print
		' @param {object} obj: Map object
		' @param {string} name: Printable object's name
		' @param {array} keys: Object's properties
		''''''''''
		printKeyValue: sub(method as string, obj as object, name = "objName" as string, keys = [] as object)
			valueType = Type(obj)
			isObj = (valueType = "roAssociativeArray" or valueType = "roSGNode")
			if (not isObj) then m.printDebug(method, name + " This is not an object"): return

			msg = {}
			if (keys.count() = 0)
				msg.oKeys = obj.keys()
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
			filteredObj = invalid

			m.printDebug(method, msg)
			msg = invalid
		end sub,

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

		''''''''''
		' stop: stop running an application
		'
		' @param {string}? Method where it placed
		' @param {msg}? Some data
		''''''''''
		stop: sub(method = "Undefined" as string, msg = invalid as dynamic)
			if msg = invalid then msg = "STOP"
			m.printDebug(method, msg)
			stop
		end sub,

		' PRIVATE

		''''''''''
		' _compoundMessage: Build printable message
		'
		' @param {string} method: Where is places print
		' @param {dynamic} msg: What to print
		' @return {string}
		''''''''''
		_compoundMessage: function(method as string, msg as dynamic) as string
			fullMessage = (function(fileOrClassName$ as string, method as string, lineDelimeter$ as string) as string
				timeStamp = function() as string
					addZeroPrefix = function(value as integer) as string
						if (value < 10) then return Substitute("0{0}", value.toStr())
						return value.toStr()
					end function
					dateTime = CreateObject("roDateTime")
					return Substitute("{0}:{1}:{2}.{3}", addZeroPrefix(dateTime.GetHours()), addZeroPrefix(dateTime.GetMinutes()), addZeroPrefix(dateTime.GetSeconds()), dateTime.GetMilliseconds().toStr())
				end function
				debugText = Substitute("{0}{1}DebugUtils", timeStamp(), lineDelimeter$)
				if (fileOrClassName$ = "" or fileOrClassName$ = method) then return Substitute("{1}{2}{1} {0}()", method, lineDelimeter$, debugText)
				return Substitute("{2}{3}{2} {0}.{1}()", fileOrClassName$, method, lineDelimeter$, debugText)
			end function)(m.fileOrClassName$, method, m.lineDelimeter$)
			message = ""
			if (msg <> invalid) then message = m._convertToStr(msg)

			if (Len(message) > 0) then fullMessage += Substitute("{1}i: {0}", message, Chr(10))
			message = invalid

			return fullMessage
		end function,

		''''''''''
		' _dashLine: print dash line with message length
		'
		' @param {integer} length: length of string
		''''''''''
		_dashLine: sub(length as integer)
			if (length > m.maxDashLineLength) then length = m.maxDashLineLength
			print string(length, m.lineDelimeter$)
		end sub,

		''''''''''
		' _convertToStr: simple string converter
		'
		' @param {dynamic} value: Convertable value
		' @return {string}
		''''''''''
		_convertToStr: function(value as dynamic) as string
			try
				valueType = Type(value)

				if (valueType = "Integer" or valueType = "roInt" or valueType = "roInteger"or valueType = "Float" or valueType = "roFloat" or valueType = "Double" or valueType = "roDouble" or valueType = "LongInteger" or valueType = "roLongInteger" or valueType = "Boolean" or valueType = "roBoolean") then return m._hasType(valueType, value.toStr())

				if (valueType = "String" or valueType = "roString") then return m._hasType(valueType, Substitute("{1}{0}{1}", value, m.quote))

				if (valueType = "roAssociativeArray" or valueType = "roSGNode") then return m._hasType(valueType, m._convertAssocArrayToStr(value))

				if (valueType = "roArray" or valueType = "roList") then return m._hasType(valueType, m._convertListToStr(value))

				if (valueType = "<uninitialized>") then return Substitute("{1}{0}{1}", valueType, m.quote)

				if (value = invalid) then return Substitute("{0}invalid{0}", m.quote)

				if (valueType = "roRegistry") then return m._hasType(valueType, m._convertListToStr(value.GetSectionList()))
				if (valueType = "roRegistrySection") then return m._hasType(valueType, m._convertListToStr(value.GetKeyList()))

				return Substitute("{1}{0}{1}", valueType, m.quote)
			catch err
				return "error: " + err.message
			end try
			return ""
		end function,

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

			if (nodeKeys.Count() > 0)
				lastKey = nodeKeys[nodeKeys.Count() - 1]
				for each nodeKey in nodeKeys
					convertedValue = m._convertToStr(obj[nodeKey])
					initSpace = (function(inOneLinePrintable as boolean) as string
						if (inOneLinePrintable) then return ""
						return " "
					end function)(m.inOneLinePrintable)

					message += Substitute("{3}{2}{0}{2}:{1}", nodeKey, convertedValue, m.quote, initSpace)
					if (nodeKey <> lastKey) then message += eonL
				end for
			end if

			if m.inOneLinePrintable then return Substitute("{{0}}", message)
			return Substitute("{{1}{0}{1}}", message, Chr(10))
		end function,

		''''''''''
		' _convertListToStr: roList, roArray string converter
		'
		' @param {object} obj: A or List
		' @return {string}
		''''''''''
		_convertListToStr: function(obj as object) as string
			message = ""
			countOff = obj.Count()
			if (countOff > 0)
				lastIndex = countOff - 1
				for i = 0 to lastIndex
					if (i > 0 and i <= lastIndex) then message += ", "
					message += m._convertToStr(obj[i])
				end for
			end if
			return Substitute("[{0}]", message)
		end function,

		''''''''''
		' _getDblQuotes: make quotes
		'
		' @return {string}
		''''''''''
		_getDblQuotes: function() as string
			return string(2, m.quote)
		end function,

		''''''''''
		' _hasType: Check and add a type of value before it, rounded typePrintOptions array values
		'
		' @param {string} typeOf: Value's type
		' @param {string} inputData: Value's data
		' @return {string}
		''''''''''
		_hasType: function(typeOf as string, inputData as string) as string
			if m.typePrintable
				return Substitute("{1}{0}{2}{3}", typeOf, m.typePrintOptions[0], m.typePrintOptions[1], inputData)
			end if
			return inputData
		end function,
	}

	m._debugUtilsSingelton = instance

	return m._debugUtilsSingelton
end function
