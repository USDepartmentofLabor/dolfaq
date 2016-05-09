class FaqsController < ApplicationController
  before_action :init
  
  def init
    @context = GovSdk::DataContext.new Dolfaq::API_HOST, Dolfaq::API_KEY, Dolfaq::API_DATA, Dolfaq::API_URI
    @request = GovSdk::DataRequest.new @context
    
  end
  def index
    @id = '1'
    @topics = call_FAQ('FAQ/Topics','1','TopicID','TopicValue').sort_by {|key, val| val }
    render 'index' 

  end

  def show
    @id = params[:id]
    tid = nil
    @request.call_api 'FAQ/TopicQuestions', :select => 'Question,Answer,TopicID',
                    :filter => "FAQID eq #{@id}"  do |results,error|
      if error
        @question = error
        @answer = Dolfaq::MISSING_STRING
        @topic = Dolfaq::MISSING_STRING
      else
        @question = results.xpath('//d:Question').first.text
        @answer = results.xpath('//d:Answer').first.text
        tid = results.xpath('//d:TopicID').first.text
      end
    end
    @request.wait_until_finished
    unless tid.nil?
      @topic = get_topic_value(tid)
    end
    render 'show'  
  end
  
  def topics
    @id = params[:id]
    @subtopics = call_FAQ('FAQ/SubTopics','TopicID','SubTopicID','SubTopicValue').sort_by {|key, val| val }
    @questions = call_FAQ('FAQ/TopicQuestions','TopicID','FAQID','Question')
    @topic = get_topic_value(@id)
    render 'topics'                   
    
  end
  
  def subtopics
    @id = params[:id]
    @questions = call_FAQ('FAQ/TopicQuestions','SubTopicID','FAQID','Question')
    st = call_FAQ('FAQ/SubTopics','SubTopicID','TopicID','SubTopicValue')
    @topic = get_topic_value(st.keys[0])
    @subtopic = st.values[0]
    render 'subtopics'
  end
  
  
  private
  def call_FAQ(table,filter_col,id_col,val_col)
    retval = Hash.new
    @request.call_api table, :select => "#{id_col},#{val_col}",
      :filter => "#{filter_col} eq #{@id}" do |results, error|
        if error
          retval[Dolfaq::ERR] = Dolfaq::MISSING_ID
        else
          value = results.xpath("//d:#{val_col}")
          key = results.xpath("//d:#{id_col}")
          key.each_with_index do |i,v|
            retval[i.text] = value[v].text
          end
        end
      end  
      @request.wait_until_finished
      retval
  end
  
  def get_topic_value(tid)
    retval = ""
    @request.call_api 'FAQ/Topics', :select => 'TopicValue', :filter => "TopicID eq #{tid}" do |results, error|
      if error
        retval = error
      else
        retval =  results.xpath('//d:TopicValue').first.text
      end
    end
    @request.wait_until_finished
    retval
    
  end
    
  
end
