# frozen_string_literal: true

module GraphQL
  module PersistedQueries
    module StoreAdapters
      # Memory adapter for storing persisted queries
      class RedisWithLocalCacheStoreAdapter < BaseStoreAdapter
        DEFAULT_REDIS_ADAPTER_CLASS = RedisStoreAdapter
        DEFAULT_MEMORY_ADAPTER_CLASS = MemoryStoreAdapter

        # rubocop:disable Metrics/ParameterLists
        def initialize(redis_client: {}, expiration: nil, namespace: nil, redis_adapter_class: nil,
                       memory_adapter_class: nil, marshal_query: false)
          redis_adapter_class ||= DEFAULT_REDIS_ADAPTER_CLASS
          memory_adapter_class ||= DEFAULT_MEMORY_ADAPTER_CLASS

          @redis_adapter = redis_adapter_class.new(
            redis_client: redis_client,
            expiration: expiration,
            namespace: namespace
          )
          @marshal_query = marshal_query
          @memory_adapter = memory_adapter_class.new(amrshal_query: @marshal_query)
          @name = :redis_with_local_cache
        end
        # rubocop:enable Metrics/ParameterLists

        def fetch(hash)
          result = @memory_adapter.fetch(hash)
          result ||= begin
            inner_result = @redis_adapter.fetch(hash)
            @memory_adapter.save(hash, inner_result) if inner_result
            inner_result
          end
          result
        end

        def save(hash, query)
          serialized_query = serialize(query)
          if @marshal_query
            @redis_adapter.save(hash, serialized_query)
          else
            @redis_adapter.save(hash, query)
          end
          @memory_adapter.save(hash, serialized_query)
        end

        def serialize(query)
          query
        end

        def deserialize(serialized_query)
          serialized_query
        end

        private

        attr_reader :redis_adapter, :memory_adapter
      end
    end
  end
end
