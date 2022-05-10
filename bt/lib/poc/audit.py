#!/usr/bin/env python3
 
    
    
def cache_audit(next_peek): 
    """ 
    A more thorough, more expensive technique to maintain cache integrity. 
    Triggers mostly when problems persist at the state of the level 1 cache. 
    
    Identifies issues such as multiple sso login sources, and 
    seamlessly purging expired creds.
      
    -- ~/.aws/sso vs ~/.aws/cli
    -- aws-sso-util vs botocore 
    -- aws-vault 
    
    In short, a lot of issues can come up.  The audit fixes what it can, and 
    logs the rest for later research.  Occcasionally as needed, it wipes and 
    restores all temporary credentials as a kind of 'global reset button.'

    NOTE: By default, we log everything that happens during a cache_audit. 
    """
     
    try:
        raw_peek, raw_sig = os.environ["BT_HINTS"], os.environ["BT_SIG"]
        this_peek = bt_decode(raw_peek, raw_sig)
        logging.info(f"Decoded current from BT_HINTS: {loads(this_peek)}")
        logging.info(f"Got next_peek from caller: {loads(next_peek)}")
    except KeyError as e:
        logging.error(f"failed to get json object: {this_peek}")
    raise BTEnvironmentError(f"Did not get json objects: {e.args[0]})

    
    # compare new_peek with this_peek
    # Look for session expirations or credential corruption. 

    # procedure:
    # 1.) compare current .asserts with new .asserts. 
    mask = jq.one(".assert", peek)
    
    # 2.) compare current and new .positions.
    # 3.) for each position (low to high)
    # -- id or token different? if so, add to change array.
    # -- compare current and new 'expires' array.  differences?
    #    NOTE: if token or id changes, expire time SHOULD ALSO CHANGE. 
    #    -- if not, this likely means corruption, or a bug. 
    #    -- flag all expired creds for mark-and-sweep. 
    #       (but if they have been replaced, i.e. time is further
    #       in the future, and id/tokens have new values, then we 
    #       DO NOT mark for cleanup.)
    #       jq --arg ss "$ss" ".expires | to_entries[] | select($ss)" )"
    # for each session asserted as active in the asserts array.
    # for each session flagged for deletion, remove. 
    # for each session flagged as updated, check that time is greater. 
    #        (and that creds are different.) 

    echo EXPIRE: ${EXPIRE} AWS_ID: ${AWS_ID} TOKEN: ${TOKEN}
    # here we just make sure values exist for expire, aws_id and token. 
    # we do not try to compare them.

    # Happens when a new shell opens. 
    # Loads without ENV vars, i.e. BT_HINTS must be restored.
    def set_session():

        # Look in peek first. User settings may have changed in caches, 
        # or in ENV vars, but not propagated to BT_HINTS..  otherwise,
        # find highest.
        for pos in get_asserts:
            pass
    # env_restore - triggered try / catch on getting BT_HINTS and ENV vars.
    # otherwise, env_update

    # get user assertions from previous (position) 

    # so you can recover it with an 'assume' command. 
    #"$(recover_role)" 
    #export BT_ROLE="${BT_ROLE}"
    #"$(recover_creds)" 
    # -- OR --
    # creds_lost  (this should be a try / except / raise.
    
    # ?? names     (cache_regen), (cache_persist), clean the expired
    # role by rebuilding configs.  awsume cannot do this very well --
    # needs two routines: 1.) to do a full-rebuild from bt_creds info. 
    # NOTE: must also restore qventus role with new active (if that is
    # what expired).  2.) Need a routine to wipe a single expired role. 
    
    # No creds currently active or expired in SSO cache; bt_creds
    # (awsume); or in ENV.  Reset the role based on AWS, after proof.
    # found_role="$( aws-whoami               | \
    #       ggrep AssumedRole              | \
    #       gawk '{print $2}'              | \
    #       sed -e 's/qv-gbl-//' 2> /dev/null)"
    # AWS is a higher authority than us.  If there's a discrepency,
    # adapt to it.
    
    # env_update - must be done last, to propagate ini file changes, and
    # AWS changes.  
    
    # A role has expired: was it the active role?  yes: qventus needs
    # updated in bt_creds, along with the expiring role. Also, BT_<poc>
    # needs updated. Start updating components to use the BT_HINTS
    # rather than BT_<POC>. Simpler. 

    env_update
    return

