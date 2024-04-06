//
//  MessageParameter.swift
//
//
//  Created by James Rochabrun on 1/28/24.
//

import Foundation

/*
 Create a Message.
 Send a structured list of input messages, and the model will generate the next message in the conversation.
 Messages can be used for either single queries to the model or for multi-turn conversations.
 The Messages API is currently in beta. During beta, you must send the anthropic-beta: messages-2023-12-15 header in your requests. If you are using our client SDKs, this is handled for you automatically.
 */


/// [Create a message.](https://docs.anthropic.com/claude/reference/messages_post)
///  POST -  https://api.anthropic.com/v1/messages
public struct MessageParameter: Encodable {
   
   /// The model that will complete your prompt.
   // As we improve Claude, we develop new versions of it that you can query. The model parameter controls which version of Claude responds to your request. Right now we offer two model families: Claude, and Claude Instant. You can use them by setting model to "claude-2.1" or "claude-instant-1.2", respectively.
   /// See [models](https://docs.anthropic.com/claude/reference/selecting-a-model) for additional details and options.
   let model: String
   
   /// Input messages.
   /// Our models are trained to operate on alternating user and assistant conversational turns. When creating a new Message, you specify the prior conversational turns with the messages parameter, and the model then generates the next Message in the conversation.
   /// Each input message must be an object with a role and content. You can specify a single user-role message, or you can include multiple user and assistant messages. The first message must always use the user role.
   /// If the final message uses the assistant role, the response content will continue immediately from the content in that message. This can be used to constrain part of the model's response.
   let messages: [Message]
   

   // Tools the model can use in responses to the user (https://docs.anthropic.com/claude/docs/tool-use)
   let tools: [ToolDefinition]?

   /// The maximum number of tokens to generate before stopping.
   /// Note that our models may stop before reaching this maximum. This parameter only specifies the absolute maximum number of tokens to generate.
   /// Different models have different maximum values for this parameter. See [input and output](https://docs.anthropic.com/claude/reference/input-and-output-sizes) sizes for details.
   let maxTokens: Int
   
   /// System prompt.
   /// A system prompt is a way of providing context and instructions to Claude, such as specifying a particular goal or role. See our [guide to system prompts](https://docs.anthropic.com/claude/docs/how-to-use-system-prompts).
   let system: String?
   
   /// An object describing metadata about the request.
   let metadata: MetaData?
   
   /// Custom text sequences that will cause the model to stop generating.
   /// Our models will normally stop when they have naturally completed their turn, which will result in a response stop_reason of "end_turn".
   /// If you want the model to stop generating when it encounters custom strings of text, you can use the stop_sequences parameter. If the model encounters one of the custom sequences, the response stop_reason value will be "stop_sequence" and the response stop_sequence value will contain the matched stop sequence.
   var stopSequences: [String]
   
   /// Whether to incrementally stream the response using server-sent events.
   /// See [streaming](https://docs.anthropic.com/claude/reference/messages-streaming for details.
   var stream: Bool
   
   /// Amount of randomness injected into the response.
   /// Defaults to 1. Ranges from 0 to 1. Use temp closer to 0 for analytical / multiple choice, and closer to 1 for creative and generative tasks.
   let temperature: Double?
   
   /// Only sample from the top K options for each subsequent token.
   /// Used to remove "long tail" low probability responses. [Learn more technical details here](https://towardsdatascience.com/how-to-sample-from-language-models-682bceb97277).
   let topK: Int?
   
   /// Use nucleus sampling.
   /// In nucleus sampling, we compute the cumulative distribution over all the options for each subsequent token in decreasing probability order and cut it off once it reaches a particular probability specified by top_p. You should either alter temperature or top_p, but not both.
   let topP: Double?
   
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens
        case system
        case tools
        case metadata
        case stopSequences
        case stream
        case temperature
        case topK
        case topP
    }
    
    public struct ToolDefinition: Encodable {
        let name: String
        let description: String
        let inputSchema: JSONSchema

        enum CodingKeys: String, CodingKey {
           case name
           case description
           case inputSchema
        }

        public init(name: String, description: String, parameters: JSONSchema) {
            self.name = name
            self.description = description
            self.inputSchema = parameters
        }
    }

    
   public struct Message: Encodable {
      
      let role: String
      let content: Content
      
      public enum Role: String {
         case user
         case assistant
      }
      
      public enum Content: Encodable {
         
         case text(String)
         case list([ContentObject])
         
         // Custom encoding to handle different cases
         public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .text(let text):
               try container.encode(text)
            case .list(let objects):
               try container.encode(objects)
            }
         }
         
         public enum ContentObject: Encodable {
            case text(String)
            case image(ImageSource)
            
            // Custom encoding to handle different cases
            public func encode(to encoder: Encoder) throws {
               var container = encoder.container(keyedBy: CodingKeys.self)
               switch self {
               case .text(let text):
                  try container.encode("text", forKey: .type)
                  try container.encode(text, forKey: .text)
               case .image(let source):
                  try container.encode("image", forKey: .type)
                  try container.encode(source, forKey: .source)
               }
            }
            
            enum CodingKeys: String, CodingKey {
               case type
               case source
               case text
            }
         }
         
         public struct ImageSource: Encodable {
            
            let type: String
            let mediaType: String
            let data: String
            
            public enum MediaType: String, Encodable {
               case jpeg = "image/jpeg"
               case png = "image/png"
               case gif = "image/gif"
               case webp = "image/webp"
            }
            
            public enum ImageSourceType: String, Encodable {
               case base64
            }
            
            public init(
               type: ImageSourceType,
               mediaType: MediaType,
               data: String)
            {
               self.type = type.rawValue
               self.mediaType = mediaType.rawValue
               self.data = data
            }
         }
      }
      
      public init(
         role: Role,
         content: Content)
      {
         self.role = role.rawValue
         self.content = content
      }
   }
   
   public struct MetaData: Encodable {
      // An external identifier for the user who is associated with the request.
      // This should be a uuid, hash value, or other opaque identifier. Anthropic may use this id to help detect abuse. Do not include any identifying information such as name, email address, or phone number.
      let userId: UUID
   }
    
        
   public init(
      model: Model,
      messages: [Message],
      maxTokens: Int,
      system: String? = nil,
      tools: [ToolDefinition]? = [],
      metadata: MetaData? = nil,
      stopSequences: [String] = [],
      stream: Bool = false,
      temperature: Double? = nil,
      topK: Int? = nil,
      topP: Double? = nil)
   {
      self.model = model.value
      self.messages = messages
      self.tools = tools
      self.maxTokens = maxTokens
      self.system = system
      self.metadata = metadata
      self.stopSequences = stopSequences
      self.stream = stream
      self.temperature = temperature
      self.topK = topK
      self.topP = topP
   }
}



// TODO own file
//
//  JSONSchema.swift
//
//
//  Created by Federico Vitale on 14/11/23.
//
// borrowed from https://github.com/rawnly/SwiftOpenAI

import Foundation

/// See the [guide](/docs/guides/gpt/function-calling) for examples, and the [JSON Schema reference](https://json-schema.org/understanding-json-schema/) for documentation about the format.
public struct JSONSchema: Codable, Equatable {
    public let type: JSONType
    public let properties: [String: Property]?
    public let required: [String]?
    public let pattern: String?
    public let const: String?
    public let enumValues: [String]?
    public let multipleOf: Int?
    public let minimum: Int?
    public let maximum: Int?
    
    // OpenAI Docs says:
    // To describe a function that accepts no parameters, provide the value {"type": "object", "properties": {}}.
    public static let empty = JSONSchema(type: .object, properties: [:])
    
    private enum CodingKeys: String, CodingKey {
        case type, properties, required, pattern, const
        case enumValues = "enum"
        case multipleOf, minimum, maximum
    }
    
    public struct Property: Codable, Equatable {
        public let type: JSONType
        public let description: String?
        public let format: String?
        public let items: Items?
        public let required: [String]?
        public let pattern: String?
        public let const: String?
        public let enumValues: [String]?
        public let multipleOf: Int?
        public let minimum: Double?
        public let maximum: Double?
        public let minItems: Int?
        public let maxItems: Int?
        public let uniqueItems: Bool?
        
        public static func string(description: String?=nil, enumValues: [String]?=nil) -> Self {
            return Property(type: .string, description: description, enumValues: enumValues)
        }
        
        public static func boolean(description: String?=nil) -> Self {
            return Property(type: .boolean, description: description)
        }
        
        public static func number(description: String?=nil) -> Self {
            return Property(type: .number, description: description)
        }

        private enum CodingKeys: String, CodingKey {
            case type, description, format, items, required, pattern, const
            case enumValues = "enum"
            case multipleOf, minimum, maximum
            case minItems, maxItems, uniqueItems
        }
        
        public init(type: JSONType, description: String? = nil, format: String? = nil, items: Items? = nil, required: [String]? = nil, pattern: String? = nil, const: String? = nil, enumValues: [String]? = nil, multipleOf: Int? = nil, minimum: Double? = nil, maximum: Double? = nil, minItems: Int? = nil, maxItems: Int? = nil, uniqueItems: Bool? = nil) {
            self.type = type
            self.description = description
            self.format = format
            self.items = items
            self.required = required
            self.pattern = pattern
            self.const = const
            self.enumValues = enumValues
            self.multipleOf = multipleOf
            self.minimum = minimum
            self.maximum = maximum
            self.minItems = minItems
            self.maxItems = maxItems
            self.uniqueItems = uniqueItems
        }
    }

    public enum JSONType: String, Codable {
        case integer
        case string
        case boolean
        case array
        case object
        case number
        case `null` = "null"
    }

    public struct Items: Codable, Equatable {
        public let type: JSONType
        public let properties: [String: Property]?
        public let pattern: String?
        public let const: String?
        public let enumValues: [String]?
        public let multipleOf: Int?
        public let minimum: Double?
        public let maximum: Double?
        public let minItems: Int?
        public let maxItems: Int?
        public let uniqueItems: Bool?

        private enum CodingKeys: String, CodingKey {
            case type, properties, pattern, const
            case enumValues = "enum"
            case multipleOf, minimum, maximum, minItems, maxItems, uniqueItems
        }
        
        public init(type: JSONType, properties: [String : Property]? = nil, pattern: String? = nil, const: String? = nil, enumValues: [String]? = nil, multipleOf: Int? = nil, minimum: Double? = nil, maximum: Double? = nil, minItems: Int? = nil, maxItems: Int? = nil, uniqueItems: Bool? = nil) {
            self.type = type
            self.properties = properties
            self.pattern = pattern
            self.const = const
            self.enumValues = enumValues
            self.multipleOf = multipleOf
            self.minimum = minimum
            self.maximum = maximum
            self.minItems = minItems
            self.maxItems = maxItems
            self.uniqueItems = uniqueItems
        }
    }
    
    public init(type: JSONType, properties: [String : Property]? = nil, required: [String]? = nil, pattern: String? = nil, const: String? = nil, enumValues: [String]? = nil, multipleOf: Int? = nil, minimum: Int? = nil, maximum: Int? = nil) {
        self.type = type
        self.properties = properties
        self.required = required
        self.pattern = pattern
        self.const = const
        self.enumValues = enumValues
        self.multipleOf = multipleOf
        self.minimum = minimum
        self.maximum = maximum
    }
}
