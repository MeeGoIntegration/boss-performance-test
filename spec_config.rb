$config = {
	"amqp" => {
        	"host" => "localhost",
        	"user" => "boss",
        	"pass" => "boss",
        	"vhost" => "boss"
    	},

	"output" => "#{ENV["HOME"]}/results",

	"atop_sample_interval" => 1,
}
