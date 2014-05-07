abstract Partitioner

type HashPartitioner <: Partitioner
#    partition_number::Int
#    total_partitions::Int
end

type NoPartitioner <: Partitioner
end

type WorkerRef # for the master
    hostname::ASCIIString
    port::Int64
    socket::Any
    active::Bool

    WorkerRef(hostname, port, socket, active) = new(hostname, port, socket, active)
    function WorkerRef(args::Dict{String, Any})
        # JSON dict -> WorkerRef
        x = new()
        x.hostname = args["hostname"]
        x.port = args["port"]
        x.socket = None
        x.active = false
        return x
    end
end

type Transformation
    name::ASCIIString
    arguments::Dict

    Transformation(name, arguments) = new(name, arguments)
    function Transformation(args::Dict{String, Any})
        x = new()
        x.name = args["name"]
        x.arguments = args["arguments"]
        return x
    end
end

type Action
    name::ASCIIString
    arguments::Dict
end

type RDD
    ID::Int64
    partitions::Dict{Int64, WorkerRef}
    dependencies::Dict{Int64, Dict{Int64, WorkerRef}}
    operation::Transformation
    partitioner::Partitioner

    RDD(ID,partitions,dependencies,operation,partitioner) = new(ID,partitions,dependencies,operation,partitioner)
    function RDD(args::Dict{String, Any})
        # Kind of awful, but needed I think to convert JSON dict -> type RDD
        x = new()
        x.ID = args["ID"]
        x.partitions = Dict{Int64, WorkerRef}()
        for p in keys(args["partitions"])
            x.partitions[int(p)] = WorkerRef(args["partitions"][p])
        end
        x.dependencies = Dict{Int64, Dict{Int64, WorkerRef}}()
        for p in keys(args["dependencies"])
            x.dependencies[int(p)] = Dict{Int64, WorkerRef}()
            for q in keys(args["partitions"][p])
                x.dependencies[int(p)][int(q)] = WorkerRef(args["partitions"][p][q])
            end
        end
        x.operation = Transformation(args["operation"])
        x.partitioner = HashPartitioner() # XXX change this for other partitioners
        return x
    end
end

type WorkerPartition
    data::Dict{Any, Array{Any}}
end

type WorkerRDD
    partitions::Dict{Int64, WorkerPartition}
    rdd::RDD
end

type Worker # for the worker
    ID::Int
    hostname::ASCIIString
    port::Int64
    active::Bool # can be turned off by an RPC

    masterhostname::ASCIIString
    masterport::Int64

    rdds::Dict{Int64, WorkerRDD}

    function Worker(hostname::ASCIIString, port::Int64)
        x = new()
        x.hostname = hostname
        x.port = port
        x.rdds = Dict{Int64, WorkerRDD}()
        x.active = true
        return x
    end
end

type Master
    hostname::ASCIIString
    port::Int64

    rdds::Dict{Int64, RDD}
    workers::Array{WorkerRef}

    function Master(hostname::ASCIIString, port::Int64)
        x = new()
        x.hostname = hostname
        x.port = port
        x.rdds = Dict{Int64, RDD}()
        x.workers = {}
        return x
    end
end
