
defmodule Env do

  def new(),do: nil

  def add(nil, key, value),do: {:node,key,value,nil,nil}
  def add({:node, key, _, left, right}, key, value),
   do: {:node,key,value,left,right}
  def add({:node, k, v, left, right}, key, value) when length(key) < length(k) do
   {:node,k,v,add(left,key,value),right}
  end
  def add({:node, k, v, left, right}, key, value) do
    {:node,k,v,left,add(right,key,value)}
  end

  def lookup(nil,_),do: {:notfound,nil}
  def lookup({:node,key,value,_,_},key), do: {key,value}
  def lookup({:node,k,_,left,right},key) do
    if length(key) < length(k), do: lookup(left,key),
              else: lookup(right,key)
  end

end

defmodule Spr2 do
  import Env

  def main(_args \\ []) do
    loop()
  end

  defp loop do
    samurai()
    IO.puts("Enter the puzzle followed by an empty line (or N to exit): ")
    str = get_input([])

    case str do
      "N" -> IO.puts("Exiting...")
      _ ->
        clear_screen()

        samurai()
        parent = self()
        pid = print_patterns_and_wait(parent)
        process(String.split(str, "\n"), 0, 1, pid)
        pid = print_patterns_and_wait(parent)
        process(String.split(str, "\n"), 0, 2, pid)

        IO.puts("Press N to exit or Enter to continue: ")

        case IO.gets("") do
          "\n" -> loop()
          "N\n"-> IO.puts("Exiting...")
        end
    end
  end

  defp clear_screen do
    System.cmd("clear", [])
  end

  defp get_input(lines) do
    case String.trim(IO.gets("")) do
      "" ->
        IO.write("\r\e[K")
        Enum.join(lines, "\n")
      "n" ->
        IO.write("\r\e[K")
        "n"
      line ->
        IO.write("\r\e[K")
        get_input(lines ++ [line])
    end
  end

  defp process([],all,part,pid) do
    wait_for_cycles_complete(pid)
    IO.puts("Puzzle answer for part #{part} = #{all}")
  end
  defp process(["" | _t], _all, _part,pid) do
    wait_for_cycles_complete(pid)
    IO.puts("no puzzle found")
  end
  defp process([h | t], all, part,pid) do


    if part == 2 do
      h13 = generate_pattern(h, 5)
      prob = String.split(h13, " ")

      seq = Enum.at(prob, 0) |> String.to_charlist()

      uno = Enum.at(prob, 1)
            |> String.split(",")
            |> Enum.map(&String.to_integer/1)

      {final, _env} = generate(seq, uno, new(), nil)

      process(t, all + final, part,pid)
    else
      prob = String.split(h, " ")
      seq = Enum.at(prob, 0) |> String.to_charlist()

      uno = Enum.at(prob, 1)
            |> String.split(",")
            |> Enum.map(&String.to_integer/1)

      {final, _env} = generate(seq, uno, new(), nil)

      process(t, all + final, part,pid)
    end
  end

  defp generate([],[],env,_),do: {1,env}
  defp generate([],[0],env,_),do: {1,env}
  defp generate([],_,env,_), do: {0,env}
  defp generate([h | t], [], env,_) do
      if h > 35, do: generate(t, [], env,46),
      else: {0,env}
  end

defp generate([63|t],[h1|t1],env,last) do
case lookup(env,[63|t]++[h1|t1]) do
  {:notfound,nil} ->
    if last == 35 do
      if h1 == 0 do
        {ans2,updenv2} =generate(t,t1,env,46)
        {ans2,add(updenv2,[63|t]++[h1|t1],ans2)}
      else
        {ans2,updenv2} =generate(t,[h1-1|t1],env,35)
        {ans2,add(updenv2,[63|t]++[h1|t1],ans2)}
      end
    else
      {ans,updenv} = generate(t,[h1|t1],env,46)
      {ans2,updenv2} =generate(t,[h1-1|t1],updenv,35)
      final=ans+ans2
      {final,add(updenv2,[63|t]++[h1|t1],final)}
    end

   {_key,value} ->   {value,env}
  end
end

defp generate([35|_t],[0|_t1],env,_), do: {0,env}
defp generate([46|_t],[h1|_t1],env,35) when h1>0, do: {0,env}
defp generate([35|t],[h1|t1],env,_), do: generate(t,[h1-1|t1],env,35)
defp generate([46|t],[0|t1],env,35), do: generate(t,t1,env,46)
defp generate([46|t],t1,env,_), do: generate(t,t1,env,46)



defp generate_pattern(str,n) do
  str1=String.split(str," ")
  repeated_pattern = List.duplicate(Enum.at(str1,0), n) |> Enum.join("?")
  repeated_numbers = List.duplicate(Enum.at(str1,1), n) |> Enum.join(",")

  result = "#{repeated_pattern} #{repeated_numbers}"
  result
end

defp print_patterns_and_wait(parent) do
  pid = spawn(fn ->
    print_patterns_cycle(["[|]", "[\\]", "[-]", "[/]"],parent)
  end)

  pid
end

defp print_patterns_cycle([],parent_pid) do
  send(parent_pid, {:cycle_completed,self(), :yes})
  print_patterns_cycle(["[|]", "[/]", "[-]","[\\]"],parent_pid)
end
defp print_patterns_cycle(patterns,parent) do
  IO.write("Processing--#{hd(patterns)}\r")
  :timer.sleep(250)
  send(parent, {:cycle_completed, :no})
  print_patterns_cycle(tl(patterns),parent)
end

defp wait_for_cycles_complete(pid) do
  receive do
    {:cycle_completed, ^pid, :yes} ->
      Process.exit(pid, :stop)
    {:cycle_completed, ^pid, :no} ->
      wait_for_cycles_complete(pid)
  end
end

defp samurai do
  IO.puts("
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⣀⣬⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⣼⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⢠⣿⡿⢹⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⣿⣺⣿⣿⣿⣿⡿⢻⣿⣿⣿⠀⠀⠀⠨⠟⠁⢸⣿⣿⣿⣿⡟⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⡇⠹⣿⣿⡏⠀⠀⠀⠀⠀⠐⣿⡿⠋⣹⣿⣄⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⠈⣿⣿⣿⣿⣿⣿⡇⠀⣿⡿⠁⠀⠀⠀⠀⠀⢀⠚⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⢹⣿⣿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡆⠀⣿⣿⣿⠋⣼⣿⠟⢹⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣎⠻⣿⣿⣿⣿⣷⠀⢸⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣧⣾⣿⣿⠏⠀⣿⡏⣠⣿⠛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡿⣾⣿⡿⠏⠀⠀⢀⣹⣷⣿⠏⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⢁⠘⢣⣿⠟⠀⠀⠀⠀⢀⣴⠆⠀⠀⠀⣠⡇⠀⠙⠋⠀⠀⠀⢀⣾⣿⣿⠁⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⡆⠀⠘⣿⣿⣿⣿⢿⡿⠁⡿⠀⠀⠀⠁⠀⠀⠀⠀⣤⣾⡟⣀⣠⣶⣾⣿⡇⠆⠀⠀⣤⣄⠐⣾⣿⣿⠿⠀⣀⣾⣿⣿⣿⠹⡆⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣏⠻⣇⠈⢻⣿⡀⠠⣿⣿⣿⣿⠈⢿⠸⣿⠀⠀⣀⠀⣤⠀⣰⣿⣿⢻⣿⡿⠋⢁⣾⣿⠃⠀⢀⣰⣿⣯⠀⢻⣿⠏⣴⣿⣿⠅⣿⣿⣿⡆⠧⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣟⠂⠉⢀⣸⣿⣿⡶⣿⣉⣭⣿⣧⡈⠀⠚⣷⣀⣿⣧⡹⣧⣿⡟⠀⢾⣿⠁⠀⣼⣿⠇⡀⠀⠸⠿⣿⡿⠀⢸⣿⢧⣿⣿⣇⠀⣿⣿⣿⡇⣾⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣴⡿⣿⠻⣿⠹⣾⠁⠀⠘⣿⣧⠀⠀⠙⡇⠙⣿⣷⠛⠃⠀⠀⠀⠁⢀⣾⣿⣷⠟⠁⠀⠀⠀⠀⠀⠀⢸⡿⠘⣿⣍⠿⠀⢹⣿⣯⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢉⡟⠁⢀⣈⣀⡈⠀⠀⠀⣸⣿⣴⡆⠀⠉⠀⠈⠉⠀⠀⠀⣴⣶⠀⣼⣿⡿⠁⠀⠀⠀⠀⢀⣄⣦⣀⢸⣷⠀⣾⣿⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣦⢾⣉⠀⢀⡭⠟⣿⢛⣿⡯⣿⣇⠀⠀⠀⠀⠀⢠⣶⡀⣿⡇⠀⢿⣿⡇⠀⠀⠀⣠⣾⣿⣿⣿⣿⡎⣿⣱⣟⣫⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⠉⣿⢸⡻⣧⣍⠙⣏⣠⣶⣭⣍⢻⣿⣾⡇⠀⣠⣾⡇⣠⡜⣿⣄⢿⣧⡀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣧⢹⣿⠉⣼⠏⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣽⣿⠀⠙⣷⣷⣤⡉⠙⣿⢇⢿⣿⣿⢇⣿⣿⣷⣾⣿⣏⣼⣿⡇⠻⣿⣧⣽⢿⡄⠀⢀⣠⣿⡛⣿⣿⣿⣿⣿⣿⡏⣨⡟⢐⡏⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⠃⠀⢀⣾⣿⣷⡿⠻⣿⣈⠓⠮⢗⠋⢸⠋⣿⡿⠻⠟⠛⠋⠀⠁⠈⡻⢿⣿⣷⣿⣿⣷⣬⣴⣿⣿⣿⣿⡿⠃⣰⣿⠇⢸⡗⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⡔⠀⢼⣿⡏⠀⠙⠺⢿⣤⣉⣉⣉⣳⣾⣿⣿⣿⣿⣶⣶⠀⠆⠀⣶⣦⠳⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⢡⣾⣿⠏⡔⢸⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣷⣸⣧⣧⡀⠚⠿⣶⣤⠀⠈⠉⠀⠀⢠⡿⠋⣽⣿⣿⣿⣆⠀⠘⢿⣿⣦⡙⢿⣿⣿⡙⠻⠛⠗⠒⠛⠟⣋⣴⣿⣇⣾⣿⡙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠓⠦⢤⣬⣭⡭⡿⠛⣿⠻⣄⠀⠻⣿⣿⣿⡿⠀⠀⠂⠙⢿⣿⣿⣌⠻⢿⣿⣷⣤⣤⣤⣾⣿⢟⣡⣾⣿⣄⠙⢆⠙⢯⡻⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⠄⣠⠤⠼⠇⠀⢸⠆⠀⢈⣿⠟⣠⡄⠀⡀⣤⣴⣼⢻⣿⣷⡀⠉⠉⣙⡉⢩⣹⡾⠻⣯⡀⠈⠻⣷⣄⠳⡄⠹⣞⢿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⡴⠃⠀⠀⢀⣦⡾⠁⠀⢸⣿⣿⠟⠁⠀⣿⣿⣿⠋⣼⣿⠿⠿⢷⣶⣤⡈⠁⣿⣄⠀⠈⠻⣦⣤⠞⠻⢆⠘⣆⢸⡎⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣧⣨⠟⠳⣤⣿⣆⣀⣀⠸⣿⣿⣄⣀⣴⣿⣿⣴⣾⢫⣥⣶⠶⢴⣯⣿⣿⡠⣿⣿⣷⣄⠀⣸⠿⣷⣤⡤⠀⢨⡼⢳⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⡤⠋⠀⠀⠘⣏⠈⡏⢹⠉⡟⣿⣏⠙⠛⠛⠋⣉⣶⣿⡏⠁⠀⠀⠙⣷⣿⣿⣿⣿⣿⣿⣗⢧⡀⠀⠀⠀⠀⣸⢃⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⣉⡠⠔⠋⠀⠀⠀⠀⣰⣏⠛⢛⣫⣿⣿⣿⣿⣶⣶⣶⣾⣿⣿⣿⣷⣄⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣷⣭⣙⣒⣒⣚⣥⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣋⣡⠤⠒⠋⠁⠀⠀⠀⠀⣀⣤⠞⡇⠈⠳⣬⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⠙⣯⠳⣄⡀⠀⠀⠈⠙⠓⠬⢭⣛⣛⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣛⠒⠒⠒⠒⠒⠒⠒⠒⣯⡉⢼⣶⣧⣀⣀⣷⢾⠟⠁⠀⠀⡀⠈⠉⠻⢦⣽⡁⠀⣿⣠⠞⠛⠲⢤⣄⡀⠀⠀⠀⢀⣉⡭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣾⣿⣿⣿⣿⣷⡀⠛⠿⠿⠙⣀⣤⣶⡾⢿⣿⡿⠿⢿⣦⣆⣀⠈⠙⠛⠡⠀⠀⣠⣿⣧⣬⣍⣉⣉⣭⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣬⣴⠞⢋⡾⠋⠀⠀⠙⠉⠀⠈⠻⣿⡉⠛⠒⣲⣤⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⣻⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣀⣀⣠⣄⣀⣀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  ")
end


end
