class ApplicationApi < Cord::BaseApi
  # abstract!
  #
  # before_action :zzz, only: 5 do
  #   puts 5
  # end

  default_scope(:abc) { |driver| driver.where('true') }
end
